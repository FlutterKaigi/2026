import { defineSecret } from "firebase-functions/params";

/**
 * プロフィール交換トークンの署名鍵。デプロイ前に以下で設定する。
 *
 * ```bash
 * firebase functions:secrets:set EXCHANGE_TOKEN_SECRET --project <プロジェクトID>
 * ```
 *
 * エミュレータでは `functions/.secret.local`（Git 管理外）に
 * `EXCHANGE_TOKEN_SECRET=<任意の値>` を書けば読み込まれる。
 */
export const exchangeTokenSecret = defineSecret("EXCHANGE_TOKEN_SECRET");
