import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

import { isEmulator } from "../env";
import { sourceDb } from "../firebase";
import { REGION } from "../region";
import { EXCHANGE_CODE_TTL_SECONDS, generateExchangeCode, isValidExchangeCodeFormat } from "./code";
import { AttemptWindow, recordAttempt } from "./rate_limit";
import { exchangeTokenSecret } from "./secret";
import { EXCHANGE_TOKEN_TTL_SECONDS, signExchangeToken } from "./token";

// Admin SDK 専用のコレクション。firestore.rules のデフォルト拒否
// (`match /{document=**} { allow read, write: if false; }`) で
// クライアントからは読み書きできない。
const EXCHANGE_CODES_COLLECTION = "exchangeCodes";
const EXCHANGE_CODE_REDEEM_ATTEMPTS_COLLECTION = "exchangeCodeRedeemAttempts";

// コード発行時の採番衝突（同じ 6 桁コードがまだ有効な状態で再発行された）を
// 検出した場合の再試行回数。10^6 通り・5 分有効という規模では実質発生しないが、
// 発生してもエラーにせず別のコードで発行し直す。
const ISSUE_CODE_MAX_ATTEMPTS = 5;

// redeemExchangeCode の総当たり対策: 呼び出し元 uid ごとに、
// 一定時間内の試行回数を制限する（コードそのものではなく呼び出し元単位にすることで、
// 総当たりで別々のコードを次々に試す攻撃も抑える）。
const REDEEM_RATE_LIMIT = {
  maxAttempts: 10,
  windowMillis: 5 * 60 * 1000,
};

interface ExchangeCodeDocument {
  uid: string;
  expiresAtMillis: number;
}

/** サインイン必須の callable 共通の前提チェック。 */
function requireAuth(auth: { uid: string } | null | undefined): { uid: string } {
  if (auth == null) {
    throw new HttpsError("unauthenticated", "サインインが必要です。");
  }
  return auth;
}

/**
 * 自分の QR コード用に、署名付き交換トークンを発行する。
 *
 * 端末にキャッシュしておけば、有効期限内（24 時間）はオフラインでも QR を
 * 表示し続けられる。
 */
export const issueExchangeToken = onCall(
  { region: REGION, enforceAppCheck: !isEmulator, secrets: [exchangeTokenSecret] },
  async (request): Promise<{ token: string; expiresInSeconds: number }> => {
    const auth = requireAuth(request.auth);
    const token = signExchangeToken(auth.uid, exchangeTokenSecret.value());
    return { token, expiresInSeconds: EXCHANGE_TOKEN_TTL_SECONDS };
  },
);

/**
 * カメラが使えない参加者向けの、6 桁コードフォールバックを発行する。
 *
 * コードは 5 分間だけ有効な使い捨てで、発行者の uid を Admin 専用コレクション
 * (`exchangeCodes`) に保存する。クライアントからは読み書きできない。
 */
export const issueExchangeCode = onCall(
  { region: REGION, enforceAppCheck: !isEmulator },
  async (request): Promise<{ code: string; expiresInSeconds: number }> => {
    const auth = requireAuth(request.auth);
    const db = sourceDb();
    const expiresAtMillis = Date.now() + EXCHANGE_CODE_TTL_SECONDS * 1000;

    for (let attempt = 0; attempt < ISSUE_CODE_MAX_ATTEMPTS; attempt++) {
      const code = generateExchangeCode();
      const ref = db.collection(EXCHANGE_CODES_COLLECTION).doc(code);
      const claimed = await db.runTransaction(async (tx) => {
        const existing = await tx.get(ref);
        const existingData = existing.data() as ExchangeCodeDocument | undefined;
        if (existing.exists && existingData !== undefined && existingData.expiresAtMillis > Date.now()) {
          // まだ有効な他人のコードと衝突。採番し直す。
          return false;
        }
        tx.set(ref, { uid: auth.uid, expiresAtMillis } satisfies ExchangeCodeDocument);
        return true;
      });

      if (claimed) {
        logger.info("issueExchangeCode issued", { uid: auth.uid });
        return { code, expiresInSeconds: EXCHANGE_CODE_TTL_SECONDS };
      }
    }

    throw new HttpsError("aborted", "コードの発行に失敗しました。もう一度お試しください。");
  },
);

/**
 * 6 桁コードを検証し、発行者の交換トークンを返す。
 *
 * クライアントはこのトークンを使って、QR スキャン時と同じ経路
 * (`users/{me}/exchanges/{発行者のuid}` の作成) で交換を成立させる。
 * コードは検証の成否を問わず削除する（再利用・総当たりの手がかりを残さない）。
 */
export const redeemExchangeCode = onCall(
  { region: REGION, enforceAppCheck: !isEmulator, secrets: [exchangeTokenSecret] },
  async (request): Promise<{ uid: string; token: string }> => {
    const auth = requireAuth(request.auth);
    const rawCode = request.data?.code;
    if (typeof rawCode !== "string" || !isValidExchangeCodeFormat(rawCode)) {
      throw new HttpsError("invalid-argument", "code は 6 桁の数字で指定してください。");
    }

    const db = sourceDb();
    await enforceRedeemRateLimit(db, auth.uid);

    const ref = db.collection(EXCHANGE_CODES_COLLECTION).doc(rawCode);
    // get→delete を 1 つのトランザクションにまとめ、同時 redeem による二重成立を
    // 防ぐ。同じコードに対して 2 つの呼び出しがほぼ同時に来た場合、先に commit した
    // 側だけがドキュメントを読み delete できる。後着はコミット時にコンテンション
    // （読み取り集合が他方の書き込みで無効化されたこと）を検出して自動的に
    // リトライされ（クライアントライブラリの既定動作）、再読み取り時には
    // ドキュメントが既に存在しないため not-found として弾かれる。
    const data = await db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      if (!snapshot.exists) {
        throw new HttpsError("not-found", "コードが見つからないか、有効期限が切れています。");
      }
      // 単一利用トークンとして扱う。検証結果に関わらずここで削除する。
      tx.delete(ref);
      return snapshot.data() as ExchangeCodeDocument;
    });

    if (data.expiresAtMillis <= Date.now()) {
      throw new HttpsError("deadline-exceeded", "コードの有効期限が切れています。");
    }
    if (data.uid === auth.uid) {
      throw new HttpsError("failed-precondition", "自分のコードは利用できません。");
    }

    const token = signExchangeToken(data.uid, exchangeTokenSecret.value());
    logger.info("redeemExchangeCode redeemed", { issuerUid: data.uid, redeemerUid: auth.uid });
    return { uid: data.uid, token };
  },
);

/** 呼び出し元 uid ごとの試行回数を記録し、上限を超えていれば拒否する。 */
async function enforceRedeemRateLimit(db: ReturnType<typeof sourceDb>, uid: string): Promise<void> {
  const ref = db.collection(EXCHANGE_CODE_REDEEM_ATTEMPTS_COLLECTION).doc(uid);
  const now = Date.now();

  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    const previous = snapshot.exists ? (snapshot.data() as AttemptWindow) : undefined;
    const result = recordAttempt(previous, now, REDEEM_RATE_LIMIT);
    tx.set(ref, result.nextWindow);
    if (!result.allowed) {
      throw new HttpsError("resource-exhausted", "試行回数が多すぎます。しばらくしてからお試しください。");
    }
  });
}
