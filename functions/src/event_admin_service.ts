import { DocumentSnapshot, Firestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { AdminAuth, assertAdmin } from "./admin_auth";
import { operateQuizEvent } from "./quiz_service";
import { assertActiveSupportLtUser, SupportLtGetUser } from "./support_lt_auth";
import { issueSupportLtCodeForUser } from "./support_lt_service";
import { Data, eventDefinition, id, invalid, object, questionDefinition, strings, text } from "./event_admin_validation";
import { previewQuizPromotion, promoteQuizEvent, withdrawQuizPromotion } from "./quiz_promotion_service";

const PROJECTS = { stg: "flutterkaigi-2026-stg", prod: "flutterkaigi-2026-283db" } as const;
const PRESTART = ["draft", "published", "registration", "entryClosed"];

/** Only server-owned environment names may select a project. Emulator calls
 * cannot reach a live project, even if local credentials happen to allow it. */
export function eventTargetProject(environment: unknown, source: string, emulator: boolean): string {
  if (emulator && environment === "dev") return source;
  if (!emulator && (environment === "stg" || environment === "prod") && (source === PROJECTS.stg || source === PROJECTS.prod)) {
    return PROJECTS[environment];
  }
  throw new HttpsError("invalid-argument", "操作環境が不正です。");
}

interface Dependencies {
  adminDb: Firestore;
  getUser: SupportLtGetUser;
  target: (environment: unknown) => Firestore;
}

function requireBeforeStart(snapshot: DocumentSnapshot): Data {
  const data = snapshot.data();
  if (!data || data.promotionWithdrawn === true || !PRESTART.includes(data.status)) {
    throw new HttpsError("failed-precondition", "クイズ開始後は設定・問題を編集できません。");
  }
  return data;
}

/** Timestamps cross the callable boundary as ISO dates, understood by the
 * shared Dart models. Firestore internals are never serialized to clients. */
export function eventJson(value: unknown): unknown {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(eventJson);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([key, entry]) => [key, eventJson(entry)]));
  }
  return value;
}
function document(snapshot: DocumentSnapshot): Data | null {
  return snapshot.exists ? { ...snapshot.data(), id: snapshot.id } : null;
}

async function readSnapshot(db: Firestore, input: Data): Promise<Data> {
  const list = async (path: string, order?: string) => {
    const collection = db.collection(path);
    const query = order ? collection.orderBy(order) : collection;
    return (await query.get()).docs.map(document);
  };
  if (input.view === "supportLt") {
    const [code, registrations] = await Promise.all([
      db.doc("supportLtSettings/current").get(), list("supportLtRegistrations", "registeredAt"),
    ]);
    return { code: document(code), registrations: registrations.reverse() };
  }
  if (input.view === "quizEvents") {
    const [events, sponsors] = await Promise.all([list("quizEvents", "createdAt"), list("sponsors")]);
    return { events: events.filter((event) => event?.promotionWithdrawn !== true).reverse(), sponsors };
  }
  if (!["quizConsole", "quizQuestion", "quizProjection"].includes(input.view as string)) invalid("画面");
  const path = `quizEvents/${id(input.eventId)}`;
  const rawEvent = document(await db.doc(path).get());
  const event = rawEvent?.promotionWithdrawn === true ? null : rawEvent;
  if (input.view === "quizQuestion") {
    const questionPath = input.questionId == null ? null : `${path}/questions/${id(input.questionId)}`;
    const [sponsors, question, secret] = await Promise.all([
      list("sponsors"),
      questionPath ? db.doc(questionPath).get().then(document) : null,
      questionPath ? db.doc(`${questionPath}/secret/answer`).get().then(document) : null,
    ]);
    return { event, sponsors, question, secret };
  }
  const teams = await list(`${path}/teams`, "tableNumber");
  if (input.view === "quizProjection") {
    // Projection never reads entry codes, unpublished questions or answer secrets.
    const question = event?.currentQuestionId
      ? document(await db.doc(`${path}/questions/${id(event.currentQuestionId)}`).get()) : null;
    return { event, teams, question: question?.status === "draft" ? null : question };
  }
  const [participants, questions, entry, answers, sponsors] = await Promise.all([
    list(`${path}/participants`, "registeredAt"), list(`${path}/questions`, "order"),
    db.doc(`${path}/secret/entry`).get(), list(`${path}/answers`), list("sponsors"),
  ]);
  return { event, teams, participants, questions, entryCode: entry.get("code") ?? null, answers, sponsors };
}

async function saveEvent(db: Firestore, input: Data): Promise<Data> {
  const eventId = id(input.eventId);
  const ref = db.doc(`quizEvents/${eventId}`);
  const definition = eventDefinition(input);
  const { capacity } = definition;
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    const data = { ...definition, updatedAt: Timestamp.now() };
    if (snapshot.exists) {
      const current = requireBeforeStart(snapshot);
      if (capacity !== current.capacity &&
        (!["draft", "published"].includes(current.status as string) || current.admissionSlotsReady === true)) {
        throw new HttpsError("failed-precondition", "受付開始後は定員を変更できません。");
      }
      if (capacity < Number(current.participantCount ?? 0)) invalid("定員");
      tx.update(ref, data);
    } else {
      tx.create(ref, { ...data, createdAt: Timestamp.now(), status: "draft", isPublic: false, currentQuestionId: null });
    }
    return { eventId };
  });
}

async function saveQuestion(db: Firestore, input: Data, deleting = false): Promise<Data> {
  const eventId = id(input.eventId);
  const questionId = id(input.questionId);
  const eventRef = db.doc(`quizEvents/${eventId}`);
  const ref = eventRef.collection("questions").doc(questionId);
  const secretRef = ref.collection("secret").doc("answer");
  let content: Data = {}, secret: Data = {};
  if (!deleting) {
    ({ content, secret } = questionDefinition(object(input.question), object(input.secret)));
  }
  return db.runTransaction(async (tx) => {
    const [event, question] = await Promise.all([tx.get(eventRef), tx.get(ref)]);
    requireBeforeStart(event);
    if (question.exists && question.get("status") !== "draft") {
      throw new HttpsError("failed-precondition", "出題済みの問題は変更できません。");
    }
    if (deleting) {
      tx.delete(secretRef);
      tx.delete(ref);
    } else {
      if (question.exists) tx.update(ref, content);
      else tx.create(ref, { ...content, status: "draft" });
      tx.set(secretRef, secret);
    }
    return { questionId: ref.id };
  });
}

/** Authorizes against the dashboard project before obtaining any target
 * handle. The same account can operate both projects without target Auth. */
export async function administerEvent(auth: AdminAuth | undefined, raw: unknown, deps: Dependencies): Promise<unknown> {
  if (!auth) throw new HttpsError("unauthenticated", "サインインが必要です。");
  await Promise.all([assertAdmin(auth, deps.adminDb), assertActiveSupportLtUser(auth.uid, deps.getUser)]);
  const input = object(raw);
  const db = deps.target(input.environment);
  const payload = object(input.payload ?? {});
  switch (input.action) {
    case "previewQuizPromotion":
    case "promoteQuizEvent": {
      if (input.environment !== "stg") invalid("反映元の環境（STG のみ）");
      const production = deps.target("prod");
      return input.action === "previewQuizPromotion"
        ? previewQuizPromotion(db, production, payload)
        : promoteQuizEvent(db, production, payload, auth.uid);
    }
    case "withdrawQuizPromotion": {
      if (input.environment !== "prod") invalid("取り消し対象の環境（本番のみ）");
      return withdrawQuizPromotion(db, payload, auth.uid);
    }
    case "read": return eventJson(await readSnapshot(db, payload));
    case "clock": return { serverNowMs: Date.now() };
    case "issueSupportLtCode":
      return issueSupportLtCodeForUser(auth, payload, { db, adminDb: deps.adminDb, getUser: deps.getUser });
    case "quizOperation": return operateQuizEvent(auth, payload, db, deps.adminDb);
    case "saveEvent": return saveEvent(db, payload);
    case "saveQuestion": return saveQuestion(db, payload);
    case "deleteQuestion": return saveQuestion(db, payload, true);
    case "updateTeamNamePool": {
      const names = strings(payload.names, 100, (value) => text(value, 80));
      await db.doc(`quizEvents/${id(payload.eventId)}`).update({ teamNamePool: names, updatedAt: Timestamp.now() });
      return {};
    }
    case "renameTeam": {
      const name = text(payload.name, 80);
      await db.doc(`quizEvents/${id(payload.eventId)}/teams/${id(payload.teamId)}`).update({ name });
      return {};
    }
    default: return invalid("操作");
  }
}
