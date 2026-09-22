import { Firestore } from "firebase-admin/firestore";

/** Auth deletion also reaches attendees who never created a users/{uid} profile. */
export async function deleteAuthUserData(uid: string, db: Firestore): Promise<void> {
  const batch = db.batch();
  for (const collection of [
    "supportLtRegistrations",
    "supportLtRegistrationAttempts",
    "snsPostRegistrations",
    "exchangeCodeAttempts",
  ]) {
    batch.delete(db.doc(`${collection}/${uid}`));
  }
  // Writing the document that registration reads/writes forces a conflict:
  // an in-flight admission either commits before cleanup or retries and sees
  // this tombstone. Preserve its event/registration fields for the roster.
  batch.set(db.doc(`quizParticipation/${uid}`), { accountDeleted: true }, { merge: true });
  await batch.commit();

  const events = await db.collection("quizEvents").get();
  const privatePaths: string[] = [];
  for (const event of events.docs) {
    for (const collection of ["participantAccounts", "entryClaims", "entryAttempts"]) {
      privatePaths.push(`quizEvents/${event.id}/${collection}/${uid}`);
    }
  }
  for (let start = 0; start < privatePaths.length; start += 400) {
    const cleanup = db.batch();
    for (const path of privatePaths.slice(start, start + 400)) cleanup.delete(db.doc(path));
    await cleanup.commit();
  }
  // Preserve the event roster and score during the competition. It contains
  // the event nickname, not the removed account's email or provider details.
}
