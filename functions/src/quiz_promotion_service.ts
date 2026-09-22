import { createHash } from "node:crypto";
import { DocumentSnapshot, Firestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { Data, eventDefinition, id, object, questionDefinition, text } from "./event_admin_validation";

const MAX_QUESTIONS = 100;
function requireState(ok: unknown, message: string): asserts ok {
  if (!ok) throw new HttpsError("failed-precondition", message);
}

/** Read a consistent definition, including private answers. A completed STG
 * rehearsal is valid input; none of its lifecycle or attendee state is copied. */
async function definition(db: Firestore, eventId: string) {
  const ref = db.doc(`quizEvents/${eventId}`);
  const content = await db.runTransaction(async (tx) => {
    const [event, questions] = await Promise.all([
      tx.get(ref), tx.get(ref.collection("questions").orderBy("order").limit(MAX_QUESTIONS + 1)),
    ]);
    requireState(event.exists, "STG のイベントが見つかりません。");
    requireState(!questions.empty && questions.size <= MAX_QUESTIONS, "反映する問題を 1〜100 問登録してください。");
    const answers = await tx.getAll(...questions.docs.map((question) => question.ref.collection("secret").doc("answer")));
    const eventData = eventDefinition(event.data()!);
    return {
      event: eventData,
      questions: questions.docs.map((question, index) => {
        requireState(answers[index].exists, `問題 ${question.id} に正解が登録されていません。`);
        const data = questionDefinition(question.data(), answers[index].data()!);
        requireState(eventData.sponsorIds.includes(data.content.sponsorId), "問題のスポンサーをイベントにも設定してください。");
        return { id: question.id, ...data };
      }),
    };
  }, { readOnly: true });
  // Keep the entire production copy within one bounded atomic transaction.
  const json = JSON.stringify(content);
  requireState(Buffer.byteLength(json) <= 4_000_000, "イベントのデータが大きすぎます。問題数・本文を減らしてください。");
  return { ...content, revision: createHash("sha256").update(json).digest("hex") };
}

export async function previewQuizPromotion(stg: Firestore, prod: Firestore, input: Data): Promise<Data> {
  const eventId = id(input.eventId);
  const content = await definition(stg, eventId);
  const [promotion, sponsors] = await Promise.all([
    prod.doc(`quizPromotions/${eventId}`).get(),
    content.event.sponsorIds.length
      ? prod.getAll(...content.event.sponsorIds.map((sponsorId) => prod.doc(`sponsors/${sponsorId}`))) : [],
  ]);
  return {
    eventId, revision: content.revision, title: content.event.title, capacity: content.event.capacity,
    questionCount: content.questions.length, sponsorCount: content.event.sponsorIds.length,
    questions: content.questions.map((question) => ({ id: question.id, order: question.content.order, title: question.content.title })),
    missingSponsorIds: sponsors.filter((sponsor) => !sponsor.exists).map((sponsor) => sponsor.id),
    existingEventId: promotion.get("status") === "active" ? promotion.get("eventId") : null,
  };
}

function existingResult(snapshot: DocumentSnapshot, eventId: string, revision: string): Data | null {
  if (!snapshot.exists) return null;
  const promotion = snapshot.get("promotion");
  requireState(promotion?.sourceEventId === eventId && promotion?.revision === revision,
    "反映IDが異なる内容で使われています。確認画面を開き直してください。");
  requireState(snapshot.get("promotionWithdrawn") !== true,
    "この反映は取り消し済みです。再反映する場合は確認画面を開き直してください。");
  return { eventId: snapshot.id };
}

export async function promoteQuizEvent(stg: Firestore, prod: Firestore, input: Data, uid: string): Promise<Data> {
  const sourceEventId = id(input.eventId);
  const eventId = id(input.operationId);
  const revision = text(input.revision, 64);
  const ref = prod.doc(`quizEvents/${eventId}`);
  // Retrying a committed request must not overwrite production, even if STG
  // has since changed. Withdrawn copies also retain their idempotency record.
  const existing = existingResult(await ref.get(), sourceEventId, revision);
  if (existing) return existing;
  const content = await definition(stg, sourceEventId);
  requireState(content.revision === revision, "確認後に STG の内容が変更されました。確認画面を開き直してください。");
  return prod.runTransaction(async (tx) => {
    const promotionRef = prod.doc(`quizPromotions/${sourceEventId}`);
    const [event, promotion] = await tx.getAll(ref, promotionRef);
    const retry = existingResult(event, sourceEventId, revision);
    if (retry) return retry;
    requireState(promotion.get("status") !== "active", "このイベントは既に本番へ反映されています。本番側のイベントを確認してください。");
    const sponsors = content.event.sponsorIds.length
      ? await tx.getAll(...content.event.sponsorIds.map((sponsorId) => prod.doc(`sponsors/${sponsorId}`))) : [];
    requireState(sponsors.every((sponsor) => sponsor.exists), "本番に未反映のスポンサーがあります。先にスポンサーを反映してください。");
    const now = Timestamp.now();
    tx.create(ref, {
      ...content.event, status: "draft", isPublic: false, currentQuestionId: null,
      participantCount: 0, createdAt: now, updatedAt: now,
      promotion: { sourceEnvironment: "stg", sourceEventId, revision, promotedAt: now, promotedBy: uid },
    });
    for (const question of content.questions) {
      const questionRef = ref.collection("questions").doc(question.id);
      tx.create(questionRef, { ...question.content, status: "draft" });
      tx.create(questionRef.collection("secret").doc("answer"), question.secret);
    }
    tx.set(promotionRef, { eventId, revision, status: "active", promotedAt: now, promotedBy: uid });
    return { eventId };
  });
}

/** Archive an accidental import, preserving its content and audit history.
 * Reading the lifecycle and participants in the same transaction serializes
 * this with registration, publication and question operations. */
export async function withdrawQuizPromotion(prod: Firestore, input: Data, uid: string): Promise<Data> {
  const eventId = id(input.eventId);
  const ref = prod.doc(`quizEvents/${eventId}`);
  return prod.runTransaction(async (tx) => {
    const event = await tx.get(ref);
    requireState(event.exists && event.get("promotion")?.sourceEnvironment === "stg", "STG から反映したイベントのみ取り消せます。");
    if (event.get("promotionWithdrawn") === true) return { eventId };
    requireState(["draft", "published"].includes(event.get("status")) && event.get("admissionSlotsReady") !== true &&
      Number(event.get("participantCount") ?? 0) === 0 && !event.get("currentQuestionId"),
    "参加受付の準備・開始後は反映を取り消せません。参加者・回答を保護するため、自動的な初期化は行いません。");
    const sourceEventId = id(object(event.get("promotion")).sourceEventId);
    const promotionRef = prod.doc(`quizPromotions/${sourceEventId}`);
    const [promotion, questions, ...activity] = await Promise.all([
      tx.get(promotionRef), tx.get(ref.collection("questions")),
      ...["participants", "participantAccounts", "teams", "answers", "admissionSlots", "entryClaims", "entryAttempts"]
        .map((name) => tx.get(ref.collection(name).limit(1))),
    ]);
    requireState(promotion.get("eventId") === eventId && promotion.get("status") === "active", "反映履歴が一致しません。状態を確認してください。");
    requireState(activity.every((snapshot) => snapshot.empty) && questions.docs.every((question) => question.get("status") === "draft"),
      "参加者・進行データがあるため取り消せません。");
    const now = Timestamp.now();
    tx.update(ref, {
      status: "draft", isPublic: false, promotionWithdrawn: true, withdrawnAt: now, withdrawnBy: uid, updatedAt: now,
    });
    tx.update(promotionRef, { status: "withdrawn", withdrawnAt: now, withdrawnBy: uid });
    return { eventId };
  });
}
