import { App, getApps, initializeApp } from "firebase-admin/app";
import { DocumentSnapshot, Firestore, getFirestore } from "firebase-admin/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineString } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { defaultFirestore } from "./firebase_admin";
import { isEmulator } from "./environment";

export { issueExchangeToken, onProfileExchangeCreated } from "./profile_exchange";

// デプロイ先（= 同期元）と同期先のリージョン・プロジェクト設定。
// SYNC_TARGET_PROJECT_ID は functions/.env（Git 管理外）で指定する。
// 例: SYNC_TARGET_PROJECT_ID=flutterkaigi-2026-283db
const syncTargetProjectId = defineString("SYNC_TARGET_PROJECT_ID");

setGlobalOptions({ region: "asia-northeast1" });

/**
 * 同期可能なコレクション。**参照される側が先**になるよう依存順に並べる。
 *
 * `sessions.venueId` / `sessions.speakerIds` / `timelineEvents.venueId` が
 * `venues` / `speakers` を参照するため、作成・更新はこの順、削除は逆順に実行する。
 */
const SYNCABLE_COLLECTIONS = [
  "sponsors",
  "news",
  "venues",
  "speakers",
  "sessions",
  "timelineEvents",
] as const;

type SyncableCollection = (typeof SYNCABLE_COLLECTIONS)[number];

const ADMINS_COLLECTION = "admins";
const ADMIN_EMAIL_PATTERN = /^[^@]+@flutterkaigi\.jp$/;
// Firestore のバッチ書き込み上限 (500) に余裕を持たせたチャンクサイズ。
const BATCH_CHUNK_SIZE = 400;

function sourceDb(): Firestore {
  return defaultFirestore();
}

function targetDb(): Firestore {
  const projectId = syncTargetProjectId.value();
  if (!projectId) {
    throw new HttpsError(
      "failed-precondition",
      "SYNC_TARGET_PROJECT_ID が設定されていません。functions/.env を確認してください。",
    );
  }
  const currentProjectId =
    process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT;
  if (!isEmulator && projectId === currentProjectId) {
    throw new HttpsError(
      "failed-precondition",
      "同期先プロジェクトがデプロイ先プロジェクトと同一です。設定を確認してください。",
    );
  }
  const appName = `syncTarget-${projectId}`;
  const existing = getApps().find((app: App) => app.name === appName);
  const app = existing ?? initializeApp({ projectId }, appName);
  return getFirestore(app);
}

/** 呼び出しユーザーが管理者（@flutterkaigi.jp かつ admins コレクション登録済み）か検証する。 */
async function assertAdmin(auth: {
  uid: string;
  token: { email?: string; email_verified?: boolean };
}): Promise<void> {
  const email = auth.token.email;
  if (
    email === undefined ||
    auth.token.email_verified !== true ||
    !ADMIN_EMAIL_PATTERN.test(email)
  ) {
    throw new HttpsError(
      "permission-denied",
      "flutterkaigi.jp ドメインの確認済みアカウントでサインインしてください。",
    );
  }
  const adminDoc = await sourceDb()
    .collection(ADMINS_COLLECTION)
    .doc(auth.uid)
    .get();
  if (!adminDoc.exists) {
    throw new HttpsError("permission-denied", "管理者権限がありません。");
  }
}

/** リクエストで指定されたコレクション名を検証し、依存順に並べ直す。 */
function parseCollections(raw: unknown): SyncableCollection[] {
  if (!Array.isArray(raw) || raw.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "collections に同期対象のコレクション名を 1 つ以上指定してください。",
    );
  }
  const requested = new Set<string>();
  for (const value of raw) {
    if (typeof value !== "string") {
      throw new HttpsError(
        "invalid-argument",
        `コレクション名が不正です: ${JSON.stringify(value)}`,
      );
    }
    if (!SYNCABLE_COLLECTIONS.includes(value as SyncableCollection)) {
      throw new HttpsError(
        "invalid-argument",
        `同期対象外のコレクションです: ${value}`,
      );
    }
    requested.add(value);
  }
  // 呼び出し側の指定順ではなく、必ず依存順（参照される側が先）に揃える。
  return SYNCABLE_COLLECTIONS.filter((collection) => requested.has(collection));
}

/** 1 コレクション分の差分。 */
interface CollectionPlan {
  collection: SyncableCollection;
  /** 同期元の全ドキュメント（= 作成・上書き対象）。 */
  sourceDocs: DocumentSnapshot[];
  /** 同期元に存在しない同期先のドキュメント（= 削除対象）。 */
  toDelete: DocumentSnapshot[];
  created: number;
  updated: number;
  total: number;
}

export interface CollectionSyncCount {
  collection: string;
  created: number;
  updated: number;
  deleted: number;
  total: number;
}

export interface SyncCollectionsResult {
  dryRun: boolean;
  created: number;
  updated: number;
  deleted: number;
  total: number;
  /** コレクションごとの内訳（依存順）。 */
  collections: CollectionSyncCount[];
}

/** 同期元と同期先を突き合わせて、1 コレクション分の差分を求める。 */
async function planCollection(
  source: Firestore,
  target: Firestore,
  collection: SyncableCollection,
): Promise<CollectionPlan> {
  const [sourceSnap, targetSnap] = await Promise.all([
    source.collection(collection).get(),
    target.collection(collection).get(),
  ]);

  const sourceIds = new Set(sourceSnap.docs.map((doc) => doc.id));
  const targetIds = new Set(targetSnap.docs.map((doc) => doc.id));

  const toDelete = targetSnap.docs.filter((doc) => !sourceIds.has(doc.id));
  const created = sourceSnap.docs.filter(
    (doc) => !targetIds.has(doc.id),
  ).length;

  return {
    collection,
    sourceDocs: sourceSnap.docs,
    toDelete,
    created,
    updated: sourceSnap.size - created,
    total: sourceSnap.size,
  };
}

function toCount(plan: CollectionPlan): CollectionSyncCount {
  return {
    collection: plan.collection,
    created: plan.created,
    updated: plan.updated,
    deleted: plan.toDelete.length,
    total: plan.total,
  };
}

/** 同期先へバッチ書き込みする。`kind` はチャンク内で共通。 */
async function commitInChunks(
  target: Firestore,
  collection: SyncableCollection,
  docs: DocumentSnapshot[],
  kind: "set" | "delete",
): Promise<void> {
  for (let i = 0; i < docs.length; i += BATCH_CHUNK_SIZE) {
    const batch = target.batch();
    for (const doc of docs.slice(i, i + BATCH_CHUNK_SIZE)) {
      const ref = target.collection(collection).doc(doc.id);
      if (kind === "set") {
        // merge しない完全置換。
        batch.set(ref, doc.data() ?? {});
      } else {
        batch.delete(ref);
      }
    }
    await batch.commit();
  }
}

/**
 * STG（デプロイ先プロジェクト）の指定コレクションを同期先（本番）へ完全ミラーする。
 *
 * - STG に存在するドキュメントは同じ ID で作成・上書き（merge しない完全置換）
 * - STG に存在しない同期先のドキュメントは削除
 * - `data.dryRun: true` の場合は書き込みを行わず、予定件数のみ返す
 *
 * 複数コレクションを指定した場合、参照切れが起きないよう
 * 「全コレクションの作成・上書きを依存順に実行 → そのあと削除を逆順に実行」する。
 * クロスプロジェクトのバッチは張れないため、全体の原子性は保証されない。
 */
export const syncCollectionsToProd = onCall(
  {
    // ダッシュボード（Web）は App Check (reCAPTCHA v3) を有効化済み。
    // エミュレータでは App Check トークンを発行できないため無効にする。
    enforceAppCheck: !isEmulator,
    memory: "256MiB",
    timeoutSeconds: 540,
  },
  async (request): Promise<SyncCollectionsResult> => {
    if (request.auth == null) {
      throw new HttpsError("unauthenticated", "サインインが必要です。");
    }
    await assertAdmin(request.auth);

    const collections = parseCollections(request.data?.collections);
    const dryRun = request.data?.dryRun === true;

    const source = sourceDb();
    const target = targetDb();

    const plans: CollectionPlan[] = [];
    for (const collection of collections) {
      plans.push(await planCollection(source, target, collection));
    }

    const counts = plans.map(toCount);
    const result: SyncCollectionsResult = {
      dryRun,
      created: counts.reduce((sum, count) => sum + count.created, 0),
      updated: counts.reduce((sum, count) => sum + count.updated, 0),
      deleted: counts.reduce((sum, count) => sum + count.deleted, 0),
      total: counts.reduce((sum, count) => sum + count.total, 0),
      collections: counts,
    };

    if (dryRun) {
      logger.info("syncCollectionsToProd dry run", {
        ...result,
        requestedBy: request.auth.token.email,
      });
      return result;
    }

    // 参照される側から先に作成・上書きする。
    for (const plan of plans) {
      await commitInChunks(target, plan.collection, plan.sourceDocs, "set");
    }
    // 削除は逆順（参照する側から先）に実行して、参照切れの期間を作らない。
    for (const plan of [...plans].reverse()) {
      await commitInChunks(target, plan.collection, plan.toDelete, "delete");
    }

    logger.info("syncCollectionsToProd applied", {
      ...result,
      targetProjectId: syncTargetProjectId.value(),
      requestedBy: request.auth.token.email,
    });
    return result;
  },
);
