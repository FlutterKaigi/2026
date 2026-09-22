import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { FUNCTIONS_REGION, isEmulator } from "./environment";
import { defaultAuth, defaultFirestore } from "./firebase_admin";
import { administerEvent, eventTargetProject } from "./event_admin_service";

/** Uses the dashboard's existing login and server-side cross-project IAM. */
export const eventAdministration = onCall(
  { region: FUNCTIONS_REGION, enforceAppCheck: !isEmulator, timeoutSeconds: 60 },
  async (request) => {
    const source = defaultFirestore();
    const sourceProject = process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT ?? "";
    const result = await administerEvent(request.auth, request.data, {
      adminDb: source,
      getUser: (uid) => defaultAuth().getUser(uid),
      target: (environment) => {
        const projectId = eventTargetProject(environment, sourceProject, isEmulator);
        if (projectId === sourceProject) return source;
        const name = `event-admin-${projectId}`;
        const app = getApps().find((app) => app.name === name) ?? initializeApp({ projectId }, name);
        return getFirestore(app);
      },
    });
    if (!["read", "clock", "previewQuizPromotion"].includes(request.data?.action)) {
      logger.info("eventAdministration applied", {
        environment: request.data?.environment,
        targetEnvironment: request.data?.action === "promoteQuizEvent" ? "prod" : request.data?.environment,
        action: request.data?.action,
        operation: request.data?.payload?.operation,
        eventId: result && typeof result === "object" && "eventId" in result ? result.eventId : request.data?.payload?.eventId,
        sourceEventId: request.data?.action === "promoteQuizEvent" ? request.data?.payload?.eventId : undefined,
        requestedBy: request.auth?.uid,
      });
    }
    return result;
  },
);
