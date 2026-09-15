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
  await batch.commit();
}
