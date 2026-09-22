import { onCall } from "firebase-functions/v2/https";
import { defaultAuth, defaultFirestore } from "./firebase_admin";
import { FUNCTIONS_REGION, isEmulator } from "./environment";
import {
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
