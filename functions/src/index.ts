import { createPrivateKey, sign } from "node:crypto";
import { App, getApps, initializeApp } from "firebase-admin/app";
import { Firestore, getFirestore } from "firebase-admin/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

// デプロイ先（= 同期元）と同期先のリージョン・プロジェクト設定。
// SYNC_TARGET_PROJECT_ID は functions/.env（Git 管理外）で指定する。
// 例: SYNC_TARGET_PROJECT_ID=flutterkaigi-2026-283db
const syncTargetProjectId = defineString("SYNC_TARGET_PROJECT_ID");

// Sign in with Apple のトークン失効（revokeAppleToken）に使う設定。
// APPLE_TEAM_ID / APPLE_KEY_ID / APPLE_SIGN_IN_CLIENT_ID は functions/.env、
// 秘密鍵は `firebase functions:secrets:set APPLE_SIGN_IN_PRIVATE_KEY`
// （.p8 の PEM 全文）で設定する。
const appleTeamId = defineString("APPLE_TEAM_ID");
const appleKeyId = defineString("APPLE_KEY_ID");
// Firebase Console の Apple プロバイダーで Web 用に設定した Services ID。
const appleSignInClientId = defineString("APPLE_SIGN_IN_CLIENT_ID");
const appleSignInPrivateKey = defineSecret("APPLE_SIGN_IN_PRIVATE_KEY");

setGlobalOptions({ region: "asia-northeast1" });

const SPONSORS_COLLECTION = "sponsors";
const NEWS_COLLECTION = "news";
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

/** JWT 用の Base64URL エンコード。 */
function base64url(input: Buffer | string): string {
  return Buffer.from(input).toString("base64url");
}

/**
 * Apple の REST API 認証に使う client secret（ES256 署名付き JWT）を生成する。
 * https://developer.apple.com/documentation/accountorganizationaldatasharing/creating-a-client-secret
 */
function createAppleClientSecret(): string {
  const teamId = appleTeamId.value();
  const keyId = appleKeyId.value();
  const clientId = appleSignInClientId.value();
  const privateKeyPem = appleSignInPrivateKey.value();
  if (!teamId || !keyId || !clientId || !privateKeyPem) {
    throw new HttpsError(
      "failed-precondition",
      "Apple トークン失効の設定（APPLE_TEAM_ID / APPLE_KEY_ID / " +
        "APPLE_SIGN_IN_CLIENT_ID / APPLE_SIGN_IN_PRIVATE_KEY）が不足しています。",
    );
  }

  const nowSeconds = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "ES256", kid: keyId }));
  const payload = base64url(
    JSON.stringify({
      iss: teamId,
      iat: nowSeconds,
      exp: nowSeconds + 300,
      aud: "https://appleid.apple.com",
      sub: clientId,
    }),
  );
  const signingInput = `${header}.${payload}`;
  // JOSE (ES256) は DER ではなく r||s 連結（ieee-p1363）形式の署名を要求する。
  const signature = sign("sha256", Buffer.from(signingInput), {
    key: createPrivateKey(privateKeyPem),
    dsaEncoding: "ieee-p1363",
  });
  return `${signingInput}.${signature.toString("base64url")}`;
}

/**
 * Sign in with Apple のアクセストークンを失効させる。
 *
 * Web クライアントには失効 SDK がないため、アカウント削除の直前にアプリから
 * 呼び出される（iOS / Android は Firebase SDK が直接失効できるため使わない）。
 * Apple はアカウント削除時のトークン失効を要求している。
 * https://developer.apple.com/support/offering-account-deletion-in-your-app/
 */
export const revokeAppleToken = onCall(
  {
    // アプリ（Web）は App Check を有効化済み。エミュレータでは App Check
    // トークンを発行できないため無効にする。
    enforceAppCheck: !isEmulator,
    secrets: [appleSignInPrivateKey],
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  async (request): Promise<void> => {
    if (request.auth == null) {
      throw new HttpsError("unauthenticated", "サインインが必要です。");
    }
    const token = request.data?.token;
    if (typeof token !== "string" || token.length === 0) {
      throw new HttpsError("invalid-argument", "token が指定されていません。");
    }

    const clientSecret = createAppleClientSecret();
    const response = await fetch("https://appleid.apple.com/auth/revoke", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: appleSignInClientId.value(),
        client_secret: clientSecret,
        token,
        token_type_hint: "access_token",
      }),
    });
    if (!response.ok) {
      logger.error("revokeAppleToken failed", {
        status: response.status,
        uid: request.auth.uid,
      });
      throw new HttpsError(
        "internal",
        `Apple トークンの失効に失敗しました（HTTP ${response.status}）。`,
      );
    }

    logger.info("revokeAppleToken succeeded", { uid: request.auth.uid });
  },
);

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

export interface SyncNewsResult {
  dryRun: boolean;
  created: number;
  updated: number;
  deleted: number;
  total: number;
}

/**
 * STG（デプロイ先プロジェクト）の news コレクションを同期先（本番）へ完全ミラーする。
 *
 * - STG に存在するドキュメントは同じ ID で作成・上書き（merge しない完全置換）
 * - STG に存在しない同期先のドキュメントは削除
 * - `data.dryRun: true` の場合は書き込みを行わず、予定件数のみ返す
 */
export const syncNewsToProd = onCall(
  {
    // ダッシュボード（Web）は App Check (reCAPTCHA v3) を有効化済み。
    // エミュレータでは App Check トークンを発行できないため無効にする。
    enforceAppCheck: !isEmulator,
    memory: "256MiB",
    timeoutSeconds: 300,
  },
  async (request): Promise<SyncNewsResult> => {
    if (request.auth == null) {
      throw new HttpsError("unauthenticated", "サインインが必要です。");
    }
    await assertAdmin(request.auth);

    const dryRun = request.data?.dryRun === true;

    const source = sourceDb();
    const target = targetDb();

    const [sourceSnap, targetSnap] = await Promise.all([
      source.collection(NEWS_COLLECTION).get(),
      target.collection(NEWS_COLLECTION).get(),
    ]);

    const sourceIds = new Set(sourceSnap.docs.map((doc) => doc.id));
    const targetIds = new Set(targetSnap.docs.map((doc) => doc.id));

    const toDelete = targetSnap.docs.filter((doc) => !sourceIds.has(doc.id));
    const created = sourceSnap.docs.filter(
      (doc) => !targetIds.has(doc.id),
    ).length;
    const updated = sourceSnap.size - created;

    const result: SyncNewsResult = {
      dryRun,
      created,
      updated,
      deleted: toDelete.length,
      total: sourceSnap.size,
    };

    if (dryRun) {
      logger.info("syncNewsToProd dry run", {
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
        const ref = target.collection(NEWS_COLLECTION).doc(operation.doc.id);
        if (operation.kind === "set") {
          batch.set(ref, operation.doc.data());
        } else {
          batch.delete(ref);
        }
      }
      await batch.commit();
    }

    logger.info("syncNewsToProd applied", {
      ...result,
      targetProjectId: syncTargetProjectId.value(),
      requestedBy: request.auth.token.email,
    });
    return result;
  },
);
