import { region } from "firebase-functions/v1";
import { deleteAuthUserData } from "./auth_user_data";
import { FUNCTIONS_REGION } from "./environment";
import { defaultFirestore } from "./firebase_admin";

// Keep the deployed trigger name so this extends the existing Auth cleanup.
// Auth lifecycle triggers require first-generation Functions.
export const onSupportLtUserDeleted = region(FUNCTIONS_REGION)
  .runWith({ failurePolicy: true })
  .auth.user()
  .onDelete((user) => deleteAuthUserData(user.uid, defaultFirestore()));
