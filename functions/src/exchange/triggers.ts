import { FieldValue } from "firebase-admin/firestore";
import { onDocumentCreated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

import { sourceDb } from "../firebase";
import { exchangeTokenSecret } from "./secret";
import { verifyExchangeToken } from "./token";

const PROFILE_EXCHANGES_COUNTER_DOC = "profileExchanges";

/**
 * `users/{uid}/exchanges/{otherUid}` の作成をトリガーに、交換を成立させる。
 *
 * - `origin == 'mirror'`（このトリガー自身が作った側）は何もしない（ループ防止）
 * - トークンの署名・期限・uid 一致を検証し、不正なら作成されたドキュメントを削除する
 * - 相手側 `users/{otherUid}/exchanges/{uid}` を `origin: 'mirror'` で作成する
 *   （既に存在する場合は触らない = 同じ相手を再スキャンしても重複しない）
 * - 自分側の `token` を null 化して残さない
 * - 新しいペアが成立した時だけ `counters/profileExchanges` を increment する
 */
export const onProfileExchangeCreated = onDocumentCreated(
  { document: "users/{uid}/exchanges/{otherUid}", secrets: [exchangeTokenSecret] },
  async (event) => {
    const snapshot = event.data;
    if (snapshot === undefined) {
      return;
    }
    const { uid, otherUid } = event.params;
    const data = snapshot.data();

    if (data.origin === "mirror") {
      return;
    }

    const token = data.token;
    if (typeof token !== "string") {
      logger.warn("profile exchange created without a token; deleting", { uid, otherUid });
      await snapshot.ref.delete();
      return;
    }

    const verification = verifyExchangeToken(token, exchangeTokenSecret.value());
    if (!verification.valid || verification.uid !== otherUid) {
      logger.warn("invalid profile exchange token; deleting", {
        uid,
        otherUid,
        reason: verification.valid ? "uid-mismatch" : verification.reason,
      });
      await snapshot.ref.delete();
      return;
    }

    const db = sourceDb();
    const mirrorRef = db.collection("users").doc(otherUid).collection("exchanges").doc(uid);
    const counterRef = db.collection("counters").doc(PROFILE_EXCHANGES_COUNTER_DOC);

    await db.runTransaction(async (tx) => {
      const mirrorSnapshot = await tx.get(mirrorRef);
      if (!mirrorSnapshot.exists) {
        tx.set(mirrorRef, {
          createdAt: FieldValue.serverTimestamp(),
          origin: "mirror",
          token: null,
          note: null,
        });
        tx.set(counterRef, { count: FieldValue.increment(1) }, { merge: true });
      }
      // token はスキャン直後だけ必要なので、検証後は残さない。
      tx.update(snapshot.ref, { token: null });
    });

    logger.info("profile exchange verified", { uid, otherUid });
  },
);

/**
 * `users/{uid}` の削除（退会）をトリガーに、本人の交換履歴と、
 * 相手側に残ったミラーの両方を削除する。
 *
 * プロフィール本体が消えて表示できなくなるため、相手の一覧にも残さない。
 */
export const onUserProfileDeleted = onDocumentDeleted(
  "users/{uid}",
  async (event) => {
    const { uid } = event.params;
    const db = sourceDb();

    const ownExchanges = await db.collection("users").doc(uid).collection("exchanges").get();

    await Promise.all([
      ...ownExchanges.docs.map((doc) => doc.ref.delete()),
      ...ownExchanges.docs.map((doc) =>
        db.collection("users").doc(doc.id).collection("exchanges").doc(uid).delete()
      ),
    ]);

    logger.info("cleaned up profile exchanges for deleted user", { uid, count: ownExchanges.size });
  },
);
