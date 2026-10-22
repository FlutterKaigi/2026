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
    if (data.isPublic !== false) {
      throw new HttpsError("failed-precondition", "非公開のイベントのみ削除できます。");
    }
    const promotionRef = data.promotion?.sourceEnvironment === "stg"
      ? db.doc(`quizPromotions/${id(object(data.promotion).sourceEventId)}`) : null;
    const promotion = promotionRef ? await tx.get(promotionRef) : null;
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
    await deleteParticipationLocks(db, eventId);
    await deletionRef.update({ status: "deleted", completedAt: Timestamp.now(), event: FieldValue.delete() });
  }
  return { eventId };
}

async function deleteParticipationLocks(db: Firestore, eventId: string): Promise<void> {
  // Read each page inside its transaction: a lock moved to another event or
  // marked by Auth deletion must be rechecked before any cleanup commits.
  while (true) {
    const cleared = await db.runTransaction(async (tx) => {
      const locks = await tx.get(db.collection("quizParticipation").where("eventId", "==", eventId).limit(200));
      for (const lock of locks.docs) {
        if (lock.get("accountDeleted") === true) {
          tx.update(lock.ref, { eventId: FieldValue.delete(), registeredAt: FieldValue.delete() });
        } else {
          tx.delete(lock.ref);
        }
      }
      return locks.size;
    });
    if (cleared === 0) return;
  }
}
