import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { defaultAuth, defaultFirestore } from "./firebase_admin";
import { FUNCTIONS_REGION, isEmulator } from "./environment";
import { getStampRallyQrCodesForUser, scanStampRallyCodeForUser } from "./stamp_rally_service";

const stampRallyTokenSecret = defineSecret("STAMP_RALLY_TOKEN_SECRET");

export const scanStampRallyCode = onCall(
  { region: FUNCTIONS_REGION, enforceAppCheck: !isEmulator, secrets: [stampRallyTokenSecret] },
  (request) => scanStampRallyCodeForUser(request.auth, request.data, dependencies()),
);

export const getStampRallyQrCodes = onCall(
  { region: FUNCTIONS_REGION, enforceAppCheck: !isEmulator, secrets: [stampRallyTokenSecret] },
  (request) => getStampRallyQrCodesForUser(request.auth, request.data, dependencies()),
);

function dependencies() {
  const secret = stampRallyTokenSecret.value();
  if (secret.length === 0) {
    // An empty HMAC key would let anyone forge every QR code.
    logger.error("STAMP_RALLY_TOKEN_SECRET is not configured");
    throw new HttpsError("internal", "スタンプラリーを利用できません。");
  }
  return { db: defaultFirestore(), getUser: (uid: string) => defaultAuth().getUser(uid), secret };
}
