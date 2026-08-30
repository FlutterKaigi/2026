import { randomInt } from "node:crypto";

/** 6 桁コードフォールバックの有効期限（5 分）。 */
export const EXCHANGE_CODE_TTL_SECONDS = 5 * 60;

/** コードの桁数。 */
export const EXCHANGE_CODE_LENGTH = 6;

const CODE_PATTERN = /^\d{6}$/;

/** ランダムな 6 桁コード（先頭ゼロ埋め）を生成する。 */
export function generateExchangeCode(random: (max: number) => number = (max) => randomInt(max)): string {
  const value = random(10 ** EXCHANGE_CODE_LENGTH);
  return value.toString().padStart(EXCHANGE_CODE_LENGTH, "0");
}

/** ユーザー入力の妥当性を確認する（総当たり対策の前段として、明らかに不正な形式は早期に弾く）。 */
export function isValidExchangeCodeFormat(code: string): boolean {
  return CODE_PATTERN.test(code);
}
