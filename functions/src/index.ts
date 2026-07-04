import { App, getApps, initializeApp } from "firebase-admin/app";
import { Firestore, getFirestore } from "firebase-admin/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineString } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

// デプロイ先（= 同期元）と同期先のリージョン・プロジェクト設定。
// SYNC_TARGET_PROJECT_ID は functions/.env（Git 管理外）で指定する。
// 例: SYNC_TARGET_PROJECT_ID=flutterkaigi-2026-283db
const syncTargetProjectId = defineString("SYNC_TARGET_PROJECT_ID");

setGlobalOptions({ region: "asia-northeast1" });

const SPONSORS_COLLECTION = "sponsors";
const ADMINS_COLLECTION = "admins";
const ADMIN_EMAIL_PATTERN = /^[^@]+@flutterkaigi\.jp$/;
// Firestore のバッチ書き込み上限 (500) に余裕を持たせたチャンクサイズ。
const BATCH_CHUNK_SIZE = 400;

const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";

// firebase-functions SDK は認証トークン検証用に内部の名前付きアプリを先に生成する
// ことがあるため、「アプリ数 0 なら初期化」ではなくデフォルトアプリの有無で判定する。
const DEFAULT_APP_NAME = "[DEFAULT]";

function sourceDb(): Firestore {
  const existing = getApps().find((app: App) => app.name === DEFAULT_APP_NAME);
  return getFirestore(existing ?? initializeApp());
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

export interface SyncSponsorsResult {
  dryRun: boolean;
  created: number;
  updated: number;
  deleted: number;
  total: number;
}

/**
 * STG（デプロイ先プロジェクト）の sponsors コレクションを同期先（本番）へ完全ミラーする。
 *
 * - STG に存在するドキュメントは同じ ID で作成・上書き（merge しない完全置換）
 * - STG に存在しない同期先のドキュメントは削除
 * - `data.dryRun: true` の場合は書き込みを行わず、予定件数のみ返す
 */
export const syncSponsorsToProd = onCall(
  {
    // ダッシュボード（Web）は App Check (reCAPTCHA v3) を有効化済み。
    // エミュレータでは App Check トークンを発行できないため無効にする。
    enforceAppCheck: !isEmulator,
    memory: "256MiB",
    timeoutSeconds: 300,
  },
  async (request): Promise<SyncSponsorsResult> => {
    if (request.auth == null) {
      throw new HttpsError("unauthenticated", "サインインが必要です。");
    }
    await assertAdmin(request.auth);

    const dryRun = request.data?.dryRun === true;

    const source = sourceDb();
    const target = targetDb();

    const [sourceSnap, targetSnap] = await Promise.all([
      source.collection(SPONSORS_COLLECTION).get(),
      target.collection(SPONSORS_COLLECTION).get(),
    ]);

    const sourceIds = new Set(sourceSnap.docs.map((doc) => doc.id));
    const targetIds = new Set(targetSnap.docs.map((doc) => doc.id));

    const toDelete = targetSnap.docs.filter((doc) => !sourceIds.has(doc.id));
    const created = sourceSnap.docs.filter(
      (doc) => !targetIds.has(doc.id),
    ).length;
    const updated = sourceSnap.size - created;

    const result: SyncSponsorsResult = {
      dryRun,
      created,
      updated,
      deleted: toDelete.length,
      total: sourceSnap.size,
    };

    if (dryRun) {
      logger.info("syncSponsorsToProd dry run", {
        ...result,
        requestedBy: request.auth.token.email,
      });
      return result;
    }

    // set（完全置換）と delete をチャンクに分けてバッチ書き込みする。
    const operations = [
      ...sourceSnap.docs.map((doc) => ({ kind: "set" as const, doc })),
      ...toDelete.map((doc) => ({ kind: "delete" as const, doc })),
    ];
    for (let i = 0; i < operations.length; i += BATCH_CHUNK_SIZE) {
      const batch = target.batch();
      for (const operation of operations.slice(i, i + BATCH_CHUNK_SIZE)) {
        const ref = target
          .collection(SPONSORS_COLLECTION)
          .doc(operation.doc.id);
        if (operation.kind === "set") {
          batch.set(ref, operation.doc.data());
        } else {
          batch.delete(ref);
        }
      }
      await batch.commit();
    }

    logger.info("syncSponsorsToProd applied", {
      ...result,
      targetProjectId: syncTargetProjectId.value(),
      requestedBy: request.auth.token.email,
    });
    return result;
  },
);
