import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { Data, id, object } from "./event_admin_validation";

/** The tombstone outlives the entire event tree: stale saves and promotion
 * retries must never recreate an event while recursive cleanup is running. */
export async function deleteQuizEvent(db: Firestore, input: Data, uid: string): Promise<Data> {
  const eventId = id(input.eventId);
  const ref = db.doc(`quizEvents/${eventId}`);
  const deletionRef = db.doc(`quizEventDeletions/${eventId}`);
  const complete = await db.runTransaction(async (tx) => {
    const [event, deletion] = await tx.getAll(ref, deletionRef);
    if (deletion.exists) return deletion.get("status") === "deleted";
    if (!event.exists) throw new HttpsError("not-found", "イベントが見つかりません。");
    const data = event.data()!;
    if (data.status !== "draft" || data.isPublic !== false || data.admissionSlotsReady === true ||
      Number(data.participantCount ?? 0) !== 0 || data.currentQuestionId ||
      (data.teamSelectionStatus != null && data.teamSelectionStatus !== "notStarted")) {
      throw new HttpsError("failed-precondition", "参加受付・出題を開始していない非公開の下書きのみ削除できます。");
    }
    const promotionRef = data.promotion?.sourceEnvironment === "stg"
      ? db.doc(`quizPromotions/${id(object(data.promotion).sourceEventId)}`) : null;
    const [questions, participation, promotion, ...activity] = await Promise.all([
      tx.get(ref.collection("questions")),
      tx.get(db.collection("quizParticipation").where("eventId", "==", eventId).limit(1)),
      promotionRef ? tx.get(promotionRef) : null,
      ...["participants", "participantAccounts", "teams", "answers", "admissionSlots", "entryClaims", "entryAttempts", "checkInAttempts"]
        .map((name) => tx.get(ref.collection(name).limit(1))),
    ]);
    if (!participation.empty || activity.some((snapshot) => !snapshot.empty) ||
      questions.docs.some((question) => question.get("status") !== "draft")) {
      throw new HttpsError("failed-precondition", "参加者・回答・進行データがあるイベントは削除できません。");
    }
    const now = Timestamp.now();
    tx.create(deletionRef, {
      status: "deleting", requestedAt: now, requestedBy: uid,
      event: { ...data, id: eventId, deletionPending: true },
    });
    // Every lifecycle/configuration writer reads the parent. Removing it in
    // this transaction makes those concurrent writes retry and reject.
    tx.delete(ref);
    if (promotionRef && promotion?.get("eventId") === eventId) {
      tx.update(promotionRef, {
        status: "deleted", eventId: FieldValue.delete(), deletedEventId: eventId,
        deletedAt: now, deletedBy: uid,
      });
    }
    return false;
  });
  if (!complete) {
    // This also discovers descendants of a missing parent. After an ambiguous
    // or partial failure, the same request resumes cleanup under the tombstone.
    await db.recursiveDelete(ref);
    await deletionRef.update({ status: "deleted", completedAt: Timestamp.now(), event: FieldValue.delete() });
  }
  return { eventId };
}
