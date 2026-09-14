import { Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

export const ADMINS_COLLECTION = "admins";
export const ADMIN_EMAIL_PATTERN = /^[^@]+@flutterkaigi\.jp$/;

export interface AdminAuth {
  uid: string;
  token: { email?: string; email_verified?: boolean };
}

/** 呼び出しユーザーが管理者（@flutterkaigi.jp かつ admins コレクション登録済み）か検証する。 */
export async function assertAdmin(auth: AdminAuth, db: Firestore): Promise<void> {
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
  const adminDoc = await db.collection(ADMINS_COLLECTION).doc(auth.uid).get();
  if (!adminDoc.exists) {
    throw new HttpsError("permission-denied", "管理者権限がありません。");
  }
}
