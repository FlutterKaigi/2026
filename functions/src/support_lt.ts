import { region } from "firebase-functions/v1";
import { onCall } from "firebase-functions/v2/https";
import { defaultAuth, defaultFirestore } from "./firebase_admin";
import { FUNCTIONS_REGION, isEmulator } from "./environment";
import {
  deleteSupportLtUserData,
  issueSupportLtCodeForUser,
  registerSupportLtForUser,
} from "./support_lt_service";

export const issueSupportLtCode = onCall(
  { region: FUNCTIONS_REGION, enforceAppCheck: !isEmulator },
  (request) => issueSupportLtCodeForUser(request.auth, request.data, activeUserDependencies()),
);

export const registerSupportLt = onCall(
  { region: FUNCTIONS_REGION, enforceAppCheck: !isEmulator },
  (request) => registerSupportLtForUser(request.auth, request.data, activeUserDependencies()),
);

function activeUserDependencies() {
  return { db: defaultFirestore(), getUser: (uid: string) => defaultAuth().getUser(uid) };
}

// Firebase Auth lifecycle triggers use first-generation Functions. Deleting
// the Auth account is the source of truth; a profile is optional for LT entry.
export const onSupportLtUserDeleted = region(FUNCTIONS_REGION)
  .runWith({ failurePolicy: true })
  .auth.user()
  .onDelete((user) => deleteSupportLtUserData(user.uid, defaultFirestore()));
