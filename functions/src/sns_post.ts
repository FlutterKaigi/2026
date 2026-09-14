import { region } from "firebase-functions/v1";
import { defaultFirestore } from "./firebase_admin";
import { FUNCTIONS_REGION } from "./environment";

// A profile is optional for SNS registration, so clean up on Auth deletion.
export const onSnsPostUserDeleted = region(FUNCTIONS_REGION)
  .runWith({ failurePolicy: true })
  .auth.user()
  .onDelete((user) => defaultFirestore().doc(`snsPostRegistrations/${user.uid}`).delete());
