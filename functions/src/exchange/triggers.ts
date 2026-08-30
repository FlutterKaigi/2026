import { FieldValue } from "firebase-admin/firestore";
import { onDocumentCreated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

import { sourceDb } from "../firebase";
import { REGION } from "../region";
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
 *
 * 既知の制約（S1）: 「新しいペアが成立した」の判定は `mirrorRef` の存在有無のみで
 * 行っており、過去にカウント済みかどうかを覚えておく永続的な記録を持たない。
 * そのため、両者が各々の一覧から該当の交換を削除した後（削除は仕様上許可されている）
 * 片方が再スキャンすると、相手側のミラーは既に無いため「新規ペア成立」と誤判定され、
 * カウンタが二重加算されうる。データモデル上この 2 つのケース（本当に初対面 /
 * 一度交換して両者が削除した後の再交換）を区別する情報が無いため、現状は許容する。
 * 厳密化する場合は Admin 専用の `exchangePairs/{sortedUidPair}`
 * のような「カウント済みフラグ」ドキュメントを別途持たせる必要がある。
 */
export const onProfileExchangeCreated = onDocumentCreated(
  { document: "users/{uid}/exchanges/{otherUid}", region: REGION, secrets: [exchangeTokenSecret] },
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
  { document: "users/{uid}", region: REGION },
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
