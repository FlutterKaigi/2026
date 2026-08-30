import { createHmac, timingSafeEqual } from "node:crypto";

/**
 * プロフィール交換トークン。`v1.<uid>.<exp>.<sig>` の形式で、
 * QR コードやコードフォールバックの発行元 uid を証明する。
 *
 * - `uid`: トークンを発行した（= QR / コードを提示した）本人の uid
 * - `exp`: 有効期限（unix seconds）
 * - `sig`: `v1.<uid>.<exp>` を秘密鍵 (`EXCHANGE_TOKEN_SECRET`) で HMAC-SHA256
 *   署名し base64url 化した値
 *
 * `users/{uid}` はサインイン済みなら誰でも read できるため、トークンの中身は
 * 秘密情報ではない。目的は uid をそのまま QR 化しないことと、
 * 期限切れ・改ざんされたトークンでの交換を防ぐこと。
 */
export const EXCHANGE_TOKEN_VERSION = "v1";

/** トークンの有効期限（24 時間）。 */
export const EXCHANGE_TOKEN_TTL_SECONDS = 24 * 60 * 60;

/** 署名対象・生成対象になる uid の形式（Firebase Auth uid は `.` を含まない）。 */
const UID_PATTERN = /^[^.]+$/;

export type ExchangeTokenVerification =
  | { readonly valid: true; readonly uid: string }
  | { readonly valid: false; readonly reason: "malformed" | "unsupported-version" | "expired" | "bad-signature" };

/** [uid] 用の署名付きトークンを発行する。[nowMillis] はテスト用の注入点。 */
export function signExchangeToken(uid: string, secret: string, nowMillis: number = Date.now()): string {
  if (!UID_PATTERN.test(uid)) {
    throw new RangeError(`uid must not contain '.': ${uid}`);
  }
  const exp = Math.floor(nowMillis / 1000) + EXCHANGE_TOKEN_TTL_SECONDS;
  const payload = `${EXCHANGE_TOKEN_VERSION}.${uid}.${exp}`;
  return `${payload}.${sign(payload, secret)}`;
}

/**
 * [token] を検証する。署名不一致・期限切れ・形式不正のいずれも
 * `{ valid: false }` として返し、例外は投げない（呼び出し側でログの出し分けをしやすくするため）。
 */
export function verifyExchangeToken(
  token: string,
  secret: string,
  nowMillis: number = Date.now(),
): ExchangeTokenVerification {
  const parts = token.split(".");
  if (parts.length !== 4) {
    return { valid: false, reason: "malformed" };
  }
  const [version, uid, expText, signature] = parts;
  if (version !== EXCHANGE_TOKEN_VERSION) {
    return { valid: false, reason: "unsupported-version" };
  }
  if (uid.length === 0) {
    return { valid: false, reason: "malformed" };
  }
  const exp = Number(expText);
  if (!Number.isInteger(exp)) {
    return { valid: false, reason: "malformed" };
  }

  const payload = `${version}.${uid}.${exp}`;
  const expectedSignature = sign(payload, secret);
  if (!timingSafeEqualStrings(signature, expectedSignature)) {
    return { valid: false, reason: "bad-signature" };
  }
  if (Math.floor(nowMillis / 1000) > exp) {
    return { valid: false, reason: "expired" };
  }
  return { valid: true, uid };
}

function sign(payload: string, secret: string): string {
  return createHmac("sha256", secret).update(payload).digest("base64url");
}

/** 長さが異なる入力でも例外を投げず、タイミング攻撃を避けて比較する。 */
function timingSafeEqualStrings(a: string, b: string): boolean {
  const bufferA = Buffer.from(a);
  const bufferB = Buffer.from(b);
  if (bufferA.length !== bufferB.length) {
    return false;
  }
  return timingSafeEqual(bufferA, bufferB);
}
