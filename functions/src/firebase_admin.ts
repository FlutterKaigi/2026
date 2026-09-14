import { App, getApps, initializeApp } from "firebase-admin/app";
import { Firestore, getFirestore } from "firebase-admin/firestore";

// firebase-functions SDK は認証トークン検証用に内部の名前付きアプリを先に生成する
// ことがあるため、「アプリ数 0 なら初期化」ではなくデフォルトアプリの有無で判定する。
const DEFAULT_APP_NAME = "[DEFAULT]";

/** Returns the default Firestore instance for the deploy-target project. */
export function defaultFirestore(): Firestore {
  const existing = getApps().find((app: App) => app.name === DEFAULT_APP_NAME);
  return getFirestore(existing ?? initializeApp());
}
