import { HttpsError, onCall } from "firebase-functions/v2/https";
import { FUNCTIONS_REGION, isEmulator } from "./environment";
import { defaultAuth, defaultFirestore } from "./firebase_admin";
import {
  getActiveQuizUser,
  operateQuizEvent,
  registerQuizParticipantForUser,
  submitQuizAnswerForUser,
} from "./quiz_service";
const options = { region: FUNCTIONS_REGION, enforceAppCheck: !isEmulator };
export const registerQuizParticipant = onCall(options, (request) =>
  registerQuizParticipantForUser(request.auth, request.data, {
    db: defaultFirestore(),
    getUser: (uid) => defaultAuth().getUser(uid),
  }),
);
export const quizEventOperation = onCall(options, async (request) => {
  await activeAccount(request.auth);
  return operateQuizEvent(request.auth, request.data, defaultFirestore());
});
export const submitQuizAnswer = onCall(options, async (request) => {
  await activeAccount(request.auth);
  return submitQuizAnswerForUser(
    request.auth,
    request.data,
    defaultFirestore(),
  );
});
export const getQuizServerTime = onCall(options, async (request) => {
  await activeAccount(request.auth);
  return { serverNowMs: Date.now() };
});
async function activeAccount(auth: { uid: string } | undefined) {
  if (!auth) throw new HttpsError("unauthenticated", "サインインが必要です。");
  await getActiveQuizUser(auth.uid, (uid) => defaultAuth().getUser(uid));
}
