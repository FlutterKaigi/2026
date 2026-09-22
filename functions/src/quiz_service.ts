import { randomInt } from "node:crypto";
import { isDeepStrictEqual } from "node:util";
import { UserRecord } from "firebase-admin/auth";
import {
  DocumentData,
  DocumentReference,
  FieldValue,
  Firestore,
  Timestamp,
  Transaction,
} from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { assertAdmin } from "./admin_auth";

export interface QuizAuth {
  uid: string;
  token: {
    email?: string;
    email_verified?: boolean;
    firebase?: { sign_in_provider?: string };
  };
}
const TEAM_NAMES = [
  "Scaffold",
  "Hero",
  "Column",
  "Row",
  "Stack",
  "Center",
  "Padding",
  "Align",
  "Expanded",
  "Flexible",
  "Container",
  "SizedBox",
  "ListView",
  "GridView",
  "AppBar",
  "Drawer",
  "Card",
  "Chip",
  "Badge",
  "Banner",
];
const PRESTART = ["draft", "published", "registration", "entryClosed"];
function dataObject(data: unknown): Record<string, unknown> {
  if (data === null || typeof data !== "object" || Array.isArray(data))
    throw new HttpsError("invalid-argument", "リクエストが不正です。");
  return data as Record<string, unknown>;
}
function id(value: unknown, name: string): string {
  if (
    typeof value !== "string" ||
    !value ||
    value.length > 128 ||
    value.includes("/")
  )
    throw new HttpsError("invalid-argument", `${name} が不正です。`);
  return value;
}
function account(auth: QuizAuth | undefined): QuizAuth {
  if (!auth) throw new HttpsError("unauthenticated", "サインインが必要です。");
  if (
    !auth.token.firebase?.sign_in_provider ||
    auth.token.firebase.sign_in_provider === "anonymous"
  )
    throw new HttpsError(
      "permission-denied",
      "アカウントでサインインしてください。",
    );
  return auth;
}
function requireState(condition: unknown, message: string): asserts condition {
  if (!condition) throw new HttpsError("failed-precondition", message);
}
async function runQuizTransaction<T>(
  db: Firestore,
  body: (tx: Transaction) => Promise<T>,
): Promise<T> {
  try {
    return await db.runTransaction(body);
  } catch (error) {
    if (error && typeof error === "object" && "code" in error) {
      if (
        error.code === 10 ||
        error.code === "ABORTED" ||
        (error.code === 3 &&
          "details" in error &&
          error.details === "Transaction is invalid or closed.")
      ) {
        throw new HttpsError(
          "aborted",
          "混み合っています。少し待ってから同じ操作をもう一度お試しください。",
        );
      }
      if (error.code === 4)
        throw new HttpsError(
          "deadline-exceeded",
          "処理結果を確認できませんでした。同じ操作をもう一度お試しください。",
        );
      if (error.code === 14)
        throw new HttpsError(
          "unavailable",
          "一時的に接続できません。同じ操作をもう一度お試しください。",
        );
    }
    throw error;
  }
}

function eventUpdate(
  tx: Transaction,
  ref: DocumentReference,
  values: DocumentData = {},
): void {
  // Lifecycle operations serialize here; admissions read this document to
  // detect a concurrent reception close without writing a shared counter.
  tx.update(ref, {
    ...values,
    revision: FieldValue.increment(1),
    updatedAt: Timestamp.now(),
  });
}
export function splitQuizTeamSizes(n: number): number[] {
  if (n <= 0) return [];
  if (n <= 5) return [n];
  const base = Math.floor(n / 4);
  switch (n % 4) {
    case 0:
      return Array<number>(base).fill(4);
    case 1:
      return [...Array<number>(base - 1).fill(4), 5];
    case 2:
      return [...Array<number>(base - 1).fill(4), 3, 3];
    default:
      return [...Array<number>(base).fill(4), 3];
  }
}

export async function getActiveQuizUser(
  uid: string,
  getUser: (uid: string) => Promise<UserRecord>,
): Promise<UserRecord> {
  let user: UserRecord;
  try {
    user = await getUser(uid);
  } catch (error) {
    if (
      error &&
      typeof error === "object" &&
      "code" in error &&
      error.code === "auth/user-not-found"
    ) {
      throw new HttpsError(
        "unauthenticated",
        "アカウントが見つかりません。サインインし直してください。",
      );
    }
    throw error;
  }
  if (user.disabled)
    throw new HttpsError(
      "permission-denied",
      "このアカウントは利用できません。",
      { reason: "disabled-account" },
    );
  return user;
}

async function ensureQuizAdmissionSlots(
  ref: DocumentReference,
  db: Firestore,
  administrator = false,
): Promise<void> {
  if ((await ref.get()).get("admissionSlotsReady") === true) return;
  await runQuizTransaction(db, async (tx) => {
    const event = await tx.get(ref);
    requireState(event.exists, "イベントが見つかりません。");
    if (event.get("admissionSlotsReady") === true) return;
    requireState(
      (administrator
        ? ["published", "registration", "entryClosed"]
        : ["registration"]
      ).includes(event.get("status")),
      "参加受付の開始後に登録してください。",
    );
    const capacity = event.get("capacity") ?? 80;
    requireState(
      Number.isInteger(capacity) && capacity >= 3 && capacity <= 80,
      "定員は3〜80人で設定してください。",
    );
    const participants = await tx.get(ref.collection("participants"));
    const slots = await tx.get(ref.collection("admissionSlots"));
    requireState(
      participants.size <= capacity,
      "既存参加者が定員を超えています。運営が参加者を確認してください。",
    );
    for (const slot of slots.docs) tx.delete(slot.ref);
    participants.docs.forEach((participant, index) => {
      tx.set(ref.collection("admissionSlots").doc(String(index)), {
        uid: participant.id,
        registeredAt: participant.get("registeredAt") ?? Timestamp.now(),
      });
    });
    eventUpdate(tx, ref, {
      admissionSlotsReady: true,
      participantCount: FieldValue.delete(),
    });
  });
}

export async function registerQuizParticipantForUser(
  rawAuth: QuizAuth | undefined,
  rawData: unknown,
  dependencies: {
    db: Firestore;
    getUser: (uid: string) => Promise<UserRecord>;
  },
): Promise<{ registered: true }> {
  const auth = account(rawAuth);
  const data = dataObject(rawData);
  const eventId = id(data.eventId, "eventId");
  const displayName =
    typeof data.displayName === "string" ? data.displayName.trim() : "";
  if (
    !displayName ||
    [
      ...new Intl.Segmenter("ja", { granularity: "grapheme" }).segment(
        displayName,
      ),
    ].length > 20 ||
    typeof data.entryCode !== "string" ||
    !/^\d{6}$/.test(data.entryCode)
  )
    throw new HttpsError(
      "invalid-argument",
      "ニックネーム（20文字以内）と6桁の受付コードを入力してください。",
    );
  const db = dependencies.db;
  const ref = db.doc(`quizEvents/${eventId}`);
  const lockRef = db.doc(`quizParticipation/${auth.uid}`);
  const participantRef = ref.collection("participants").doc(auth.uid);
  const attemptRef = ref.collection("entryAttempts").doc(auth.uid);
  // Legacy rosters predate the global participation lock. Reading them before
  // locking the event keeps 80 arrivals from holding every event while waiting.
  // Rules prohibit old clients adding roster documents; all new admissions
  // serialize on lockRef, so concurrent registrations across rounds remain safe.
  const events = await db.collection("quizEvents").get();
  const otherRefs = events.docs
    .filter((doc) => doc.id !== eventId)
    .map((doc) => doc.ref.collection("participants").doc(auth.uid));
  const hasLegacyEnrollment =
    otherRefs.length > 0 &&
    (await db.getAll(...otherRefs)).some((doc) => doc.exists);

  await ensureQuizAdmissionSlots(ref, db);
  let result: string = "slot-taken";
  // Each occupied slot represents one participant. Admissions only read the
  // parent, so 80 callers do not contend on a shared counter or revision.
  // The parent read still conflicts with registration-close/capacity changes.
  while (result === "slot-taken") {
    const [eventSnapshot, slots] = await Promise.all([
      ref.get(),
      ref.collection("admissionSlots").get(),
    ]);
    const capacity = eventSnapshot.get("capacity") ?? 80;
    requireState(
      Number.isInteger(capacity) && capacity >= 3 && capacity <= 80,
      "定員は3〜80人で設定してください。",
    );
    const occupied = new Set(slots.docs.map((doc) => doc.id));
    const available = Array.from({ length: capacity }, (_, index) =>
      String(index),
    ).filter((slot) => !occupied.has(slot));
    const candidate = available.length
      ? available[randomInt(available.length)]
      : null;
    const slotRef = ref.collection("admissionSlots").doc(candidate ?? "0");
    result = await runQuizTransaction(db, async (tx) => {
      // Check Auth under the UID lock (also used by Auth deletion cleanup), but
      // before reading the shared event: unrelated attendees can do this in parallel.
      const lock = await tx.get(lockRef);
      if (lock.get("accountDeleted") === true) {
        throw new HttpsError(
          "unauthenticated",
          "アカウントが削除されています。サインインし直してください。",
        );
      }
      const user = await getActiveQuizUser(auth.uid, dependencies.getUser);
      const [event, participant, secret, attempt, slot] = await tx.getAll(
        ref,
        participantRef,
        ref.collection("secret").doc("entry"),
        attemptRef,
        slotRef,
      );
      requireState(event.exists, "イベントが見つかりません。");
      // Lost acknowledgements remain retryable after reception closes or rotates.
      if (participant.exists) return "registered";
      if (
        (lock.exists && lock.get("eventId") !== eventId) ||
        hasLegacyEnrollment
      )
        return "already-registered";
      requireState(
        event.get("status") === "registration",
        "参加受付は終了しています。",
      );
      const now = Timestamp.now();
      const attemptData = attempt.data();
      const recent =
        attemptData?.windowStartedAt instanceof Timestamp &&
        now.toMillis() - attemptData.windowStartedAt.toMillis() < 60_000;
      const count = recent ? Number(attemptData?.count ?? 0) : 0;
      if (count >= 5) return "rate-limited";
      if (secret.get("code") !== data.entryCode) {
        tx.set(attemptRef, {
          count: count + 1,
          windowStartedAt: recent ? attemptData?.windowStartedAt : now,
        });
        return "wrong-code";
      }
      requireState(
        event.get("admissionSlotsReady") === true,
        "参加受付の準備中です。",
      );
      if (candidate === null) return "full";
      if (Number(candidate) >= event.get("capacity")) return "slot-taken";
      if (slot.exists) return "slot-taken";
      tx.create(participantRef, { displayName, registeredAt: now });
      tx.set(ref.collection("participantAccounts").doc(auth.uid), {
        uid: auth.uid,
        email: user.email ?? null,
        accountName: user.displayName ?? null,
        photoUrl: user.photoURL ?? null,
        signInProvider: auth.token.firebase!.sign_in_provider,
        linkedAt: now,
      });
      tx.set(lockRef, { eventId, registeredAt: now });
      tx.delete(attemptRef);
      tx.create(slotRef, { uid: auth.uid, registeredAt: now });
      return "registered";
    });
  }
  if (result === "already-registered")
    throw new HttpsError(
      "already-exists",
      "別のクイズ大会に参加登録済みです。前後半への重複参加はできません。",
    );
  if (result === "rate-limited")
    throw new HttpsError(
      "resource-exhausted",
      "受付コードの確認回数が上限に達しました。1分後にお試しください。",
      { reason: "rate-limited" },
    );
  if (result === "wrong-code")
    throw new HttpsError("permission-denied", "受付コードが正しくありません。");
  if (result === "full")
    throw new HttpsError("resource-exhausted", "参加定員に達しました。", {
      reason: "full",
    });
  return { registered: true };
}

export async function submitQuizAnswerForUser(
  rawAuth: QuizAuth | undefined,
  rawData: unknown,
  db: Firestore,
): Promise<{ accepted: true; serverNowMs: number }> {
  const auth = account(rawAuth);
  const data = dataObject(rawData);
  const eventId = id(data.eventId, "eventId");
  const questionId = id(data.questionId, "questionId");
  const teamId = id(data.teamId, "teamId");
  const selected = data.selectedOptionIndex;
  if (!Number.isInteger(selected))
    throw new HttpsError("invalid-argument", "選択肢が不正です。");
  const ref = db.doc(`quizEvents/${eventId}`);
  const acceptedAt = await runQuizTransaction(db, async (tx) => {
    const [event, question, team, answer] = await tx.getAll(
      ref,
      ref.collection("questions").doc(questionId),
      ref.collection("teams").doc(teamId),
      ref.collection("answers").doc(`${questionId}_${teamId}`),
    );
    if (
      !team.exists ||
      !(team.get("memberUids") as unknown[])?.includes(auth.uid)
    )
      throw new HttpsError(
        "permission-denied",
        "自分のチームの回答のみ変更できます。",
      );
    const now = Timestamp.now();
    requireState(
      event.get("status") === "inProgress" &&
        event.get("currentQuestionId") === questionId &&
        question.get("status") === "open" &&
        question.get("closesAt") instanceof Timestamp &&
        now.toMillis() < question.get("closesAt").toMillis(),
      "回答受付は終了しています。",
    );
    requireState(
      answer.exists &&
        answer.get("questionId") === questionId &&
        answer.get("teamId") === teamId,
      "回答欄がありません。運営にお知らせください。",
    );
    if (
      (selected as number) < 0 ||
      (selected as number) >= (question.get("options") as unknown[])?.length
    )
      throw new HttpsError("invalid-argument", "選択肢が不正です。");
    tx.update(answer.ref, {
      selectedOptionIndex: selected,
      answeredBy: auth.uid,
      submittedAt: now,
    });
    return now.toMillis();
  });
  return { accepted: true, serverNowMs: acceptedAt };
}

export async function operateQuizEvent(
  rawAuth: QuizAuth | undefined,
  rawData: unknown,
  db: Firestore,
  adminDb: Firestore = db,
): Promise<Record<string, unknown>> {
  if (!rawAuth)
    throw new HttpsError("unauthenticated", "サインインが必要です。");
  await assertAdmin(rawAuth, adminDb);
  const data = dataObject(rawData);
  const eventId = id(data.eventId, "eventId");
  const operation = id(data.operation, "operation");
  const ref = db.doc(`quizEvents/${eventId}`);
  if (["openRegistration", "reopenRegistration"].includes(operation)) {
    await ensureQuizAdmissionSlots(ref, db, true);
  }
  const receiptRef = ref
    .collection("operations")
    .doc(id(data.operationId, "operationId"));
  const operationRequest = {
    operation,
    questionId:
      data.questionId == null ? null : id(data.questionId, "questionId"),
    uid: data.uid == null ? null : id(data.uid, "uid"),
    seconds: data.seconds ?? null,
  };
  if (
    operationRequest.seconds !== null &&
    !Number.isInteger(operationRequest.seconds)
  ) {
    throw new HttpsError("invalid-argument", "seconds が不正です。");
  }
  return runQuizTransaction(db, async (tx) => {
    const event = await tx.get(ref);
    requireState(event.exists, "イベントが見つかりません。");
    const eventData = event.data()!;
    requireState(eventData.promotionWithdrawn !== true, "本番への反映が取り消されたイベントです。");
    const receipt = await tx.get(receiptRef);
    if (receipt.exists) {
      requireState(
        receipt.get("operation") === operation &&
          isDeepStrictEqual(receipt.get("request"), operationRequest),
        "操作IDが異なる内容で再利用されています。",
      );
      return receipt.get("result") as Record<string, unknown>;
    }
    const finish = (
      values: DocumentData = {},
      result: Record<string, unknown> = {},
    ) => {
      eventUpdate(tx, ref, values);
      tx.create(receiptRef, {
        operation,
        request: operationRequest,
        result,
        createdAt: Timestamp.now(),
        requestedBy: rawAuth.uid,
      });
      return result;
    };
    const transitions: Record<string, [string, string]> = {
      publish: ["draft", "published"],
      unpublish: ["published", "draft"],
      openRegistration: ["published", "registration"],
      closeRegistration: ["registration", "entryClosed"],
    };
    const transition = transitions[operation];
    if (transition) {
      if (eventData.status === transition[1]) return finish();
      requireState(
        eventData.status === transition[0],
        "イベントの状態が変わりました。画面を更新してください。",
      );
      if (operation === "openRegistration") {
        const secret = await tx.get(ref.collection("secret").doc("entry"));
        requireState(
          /^\d{6}$/.test(secret.get("code") ?? ""),
          "受付コードを発行してください。",
        );
      }
      return finish({
        status: transition[1],
        isPublic: transition[1] !== "draft",
      });
    }
    if (operation === "regenerateEntryCode") {
      requireState(
        PRESTART.includes(eventData.status),
        "出題開始後は受付コードを変更できません。",
      );
      const secret = await tx.get(ref.collection("secret").doc("entry"));
      let code: string;
      do {
        code = randomInt(100000, 1000000).toString();
      } while (code === secret.get("code"));
      tx.set(secret.ref, { code, updatedAt: Timestamp.now() });
      return finish({}, { code });
    }
    if (
      [
        "reopenRegistration",
        "removeParticipant",
        "buildTeams",
        "rebuildTeams",
      ].includes(operation)
    ) {
      requireState(
        PRESTART.includes(eventData.status),
        "出題開始後は参加者・チームを変更できません。",
      );
      const participants = await tx.get(ref.collection("participants"));
      const teams = await tx.get(ref.collection("teams"));
      const questions = await tx.get(ref.collection("questions"));
      requireState(
        questions.docs.every((doc) => doc.get("status") === "draft"),
        "出題済みの問題があります。",
      );
      if (operation === "reopenRegistration") {
        if (eventData.status === "registration") return finish();
        requireState(
          eventData.status === "entryClosed",
          "受付終了後のみ再開できます。",
        );
      }
      if (operation === "buildTeams" || operation === "rebuildTeams") {
        requireState(
          eventData.status === "entryClosed",
          "参加受付を終了してからチーム編成してください。",
        );
        requireState(
          participants.size >= 3 && participants.size <= 80,
          "チーム編成には3〜80人の参加者が必要です。",
        );
        if (operation === "buildTeams" && !teams.empty) {
          const members = teams.docs.flatMap(
            (doc) => doc.get("memberUids") as string[],
          );
          requireState(
            members.length === participants.size &&
              new Set(members).size === participants.size &&
              participants.docs.every((doc) =>
                teams.docs.some(
                  (team) =>
                    team.id === doc.get("teamId") &&
                    (team.get("memberUids") as string[]).includes(doc.id),
                ),
              ),
            "既存チームが参加者と一致しません。チームを再編成してください。",
          );
          return finish();
        }
        const shuffled = [...participants.docs];
        for (let i = shuffled.length - 1; i > 0; i--) {
          const j = randomInt(i + 1);
          [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
        }
        const pool = (
          Array.isArray(eventData.teamNamePool) ? eventData.teamNamePool : []
        )
          .filter(
            (name: unknown): name is string =>
              typeof name === "string" && name.trim().length > 0,
          )
          .map((name: string) => name.trim());
        for (const team of teams.docs) tx.delete(team.ref);
        let offset = 0;
        for (const [index, size] of splitQuizTeamSizes(
          shuffled.length,
        ).entries()) {
          const teamRef = ref.collection("teams").doc();
          const members = shuffled.slice(offset, offset + size);
          offset += size;
          for (const member of members)
            tx.update(member.ref, { teamId: teamRef.id });
          tx.create(teamRef, {
            tableNumber: index + 1,
            name: pool[index] ?? TEAM_NAMES[index] ?? `Team ${index + 1}`,
            memberUids: members.map((doc) => doc.id),
            members: members.map((doc) => ({
              uid: doc.id,
              displayName: doc.get("displayName"),
            })),
            score: 0,
            rank: null,
            perfectSponsorIds: [],
          });
        }
        return finish({ participantCount: FieldValue.delete() });
      }
      let removedUid: string | undefined;
      if (operation === "removeParticipant") {
        removedUid = id(data.uid, "uid");
        const lock = await tx.get(db.doc(`quizParticipation/${removedUid}`));
        const reservations = await tx.get(
          ref.collection("admissionSlots").where("uid", "==", removedUid),
        );
        const participant = participants.docs.find(
          (doc) => doc.id === removedUid,
        );
        if (!participant) return finish();
        tx.delete(participant.ref);
        for (const reservation of reservations.docs) tx.delete(reservation.ref);
        tx.delete(ref.collection("participantAccounts").doc(removedUid));
        tx.delete(ref.collection("entryClaims").doc(removedUid));
        if (
          lock.get("eventId") === eventId &&
          lock.get("accountDeleted") !== true
        )
          tx.delete(lock.ref);
      }
      for (const team of teams.docs) tx.delete(team.ref);
      for (const participant of participants.docs)
        if (participant.id !== removedUid)
          tx.update(participant.ref, { teamId: FieldValue.delete() });
      return finish({
        ...(operation === "reopenRegistration"
          ? { status: "registration" }
          : {}),
        participantCount: FieldValue.delete(),
      });
    }
    if (operation === "finalizeEvent") {
      if (eventData.status === "finished") return finish();
      requireState(
        eventData.status === "inProgress",
        "出題後に結果を確定してください。",
      );
      const teams = await tx.get(ref.collection("teams"));
      const questions = await tx.get(ref.collection("questions"));
      const answers = await tx.get(ref.collection("answers"));
      const revealedQuestions = questions.docs.filter(
        (doc) => doc.get("status") === "revealed",
      );
      requireState(
        !teams.empty &&
          revealedQuestions.length > 0 &&
          questions.docs.every((doc) =>
            ["draft", "revealed"].includes(doc.get("status")),
          ),
        "出題済みの問題の正解をすべて発表してから結果を確定してください。",
      );
      const secrets = await tx.getAll(
        ...revealedQuestions.map((doc) =>
          doc.ref.collection("secret").doc("answer"),
        ),
      );
      const correctByQuestion = new Map(
        secrets.map((doc) => [
          doc.ref.parent.parent!.id,
          doc.get("correctOptionIndex"),
        ]),
      );
      const scores = new Map<string, number>();
      const perfectByTeam = new Map<string, string[]>();
      const sponsors = [
        ...new Set(
          revealedQuestions.map((doc) => doc.get("sponsorId") as string),
        ),
      ];
      for (const team of teams.docs) {
        const correct = new Set<string>();
        for (const question of revealedQuestions) {
          const answer = answers.docs.find(
            (doc) => doc.id === `${question.id}_${team.id}`,
          );
          if (
            answer &&
            answer.get("selectedOptionIndex") != null &&
            answer.get("selectedOptionIndex") ===
              correctByQuestion.get(question.id)
          )
            correct.add(question.id);
        }
        scores.set(team.id, correct.size * 10);
        perfectByTeam.set(
          team.id,
          sponsors.filter((sponsor) =>
            revealedQuestions
              .filter((question) => question.get("sponsorId") === sponsor)
              .every((question) => correct.has(question.id)),
          ),
        );
      }
      const ranks = [...new Set(scores.values())].sort((a, b) => b - a);
      for (const team of teams.docs)
        tx.update(team.ref, {
          score: scores.get(team.id),
          rank: ranks.indexOf(scores.get(team.id)!) + 1,
          perfectSponsorIds: perfectByTeam.get(team.id),
        });
      return finish({ status: "finished", currentQuestionId: null });
    }
    if (
      [
        "presentQuestion",
        "openQuestion",
        "closeQuestion",
        "extendQuestion",
        "revealQuestion",
      ].includes(operation)
    ) {
      requireState(
        ["entryClosed", "inProgress"].includes(eventData.status),
        "チーム編成後、結果確定前のみ出題を操作できます。",
      );
      const questionId = id(data.questionId, "questionId");
      const questionRef = ref.collection("questions").doc(questionId);
      const question = await tx.get(questionRef);
      const questions = await tx.get(ref.collection("questions"));
      const teams = await tx.get(ref.collection("teams"));
      requireState(question.exists, "問題が見つかりません。");
      const q = question.data()!;
      const active = questions.docs.filter((doc) =>
        ["reading", "open", "closed"].includes(doc.get("status")),
      );
      if (operation === "presentQuestion" || operation === "openQuestion") {
        if (
          (operation === "presentQuestion" && q.status === "reading") ||
          (operation === "openQuestion" && q.status === "open")
        ) {
          requireState(
            eventData.currentQuestionId === questionId,
            "現在の問題が一致しません。",
          );
          return finish();
        }
        requireState(
          active.every((doc) => doc.id === questionId),
          "現在の問題の正解を発表してから次の問題を出題してください。",
        );
        requireState(!teams.empty, "先にチーム編成を行ってください。");
        requireState(
          q.status === "draft" ||
            (operation === "openQuestion" && q.status === "reading"),
          "この問題は出題済みです。",
        );
        requireState(
          Array.isArray(q.options) &&
            q.options.length >= 2 &&
            q.options.length <= 4 &&
            Number.isInteger(q.durationSeconds) &&
            q.durationSeconds > 0 &&
            q.durationSeconds <= 1800,
          "選択肢・制限時間が不正です。",
        );
        const secret = await tx.get(
          questionRef.collection("secret").doc("answer"),
        );
        requireState(
          secret.exists &&
            Number.isInteger(secret.get("correctOptionIndex")) &&
            secret.get("correctOptionIndex") >= 0 &&
            secret.get("correctOptionIndex") < q.options.length,
          "正解を設定してください。",
        );
        if (operation === "presentQuestion")
          tx.update(questionRef, {
            status: "reading",
            openedAt: null,
            closesAt: null,
          });
        else {
          const now = Timestamp.now();
          tx.update(questionRef, {
            status: "open",
            openedAt: now,
            closesAt: Timestamp.fromMillis(
              now.toMillis() + q.durationSeconds * 1000,
            ),
          });
          for (const team of teams.docs)
            tx.create(
              ref.collection("answers").doc(`${questionId}_${team.id}`),
              {
                questionId,
                teamId: team.id,
                selectedOptionIndex: null,
                answeredBy: null,
                submittedAt: null,
                isCorrect: null,
              },
            );
        }
        return finish({ status: "inProgress", currentQuestionId: questionId });
      }
      if (operation === "revealQuestion" && q.status === "revealed")
        return finish();
      requireState(
        eventData.status === "inProgress" &&
          eventData.currentQuestionId === questionId,
        "現在の問題のみ操作できます。",
      );
      if (operation === "closeQuestion") {
        if (q.status === "closed") return finish();
        requireState(q.status === "open", "回答受付中の問題のみ締め切れます。");
        tx.update(questionRef, { status: "closed" });
        return finish();
      }
      if (operation === "extendQuestion") {
        const seconds = data.seconds;
        requireState(
          q.status === "open" || q.status === "closed",
          "正解発表前の問題のみ回答時間を延長できます。",
        );
        if (
          !Number.isInteger(seconds) ||
          (seconds as number) < 1 ||
          (seconds as number) > 300
        )
          throw new HttpsError(
            "invalid-argument",
            "延長は1〜300秒で指定してください。",
          );
        const closesAt = Timestamp.fromMillis(
          Math.max(Date.now(), (q.closesAt as Timestamp).toMillis()) +
            (seconds as number) * 1000,
        );
        tx.update(questionRef, { status: "open", closesAt });
        return finish({}, { closesAtMs: closesAt.toMillis() });
      }
      requireState(
        q.status === "closed",
        "回答を締め切ってから正解を発表してください。",
      );
      const secret = await tx.get(
        questionRef.collection("secret").doc("answer"),
      );
      const answers = await tx.get(ref.collection("answers"));
      requireState(
        secret.exists && Number.isInteger(secret.get("correctOptionIndex")),
        "正解が設定されていません。",
      );
      const correct = secret.get("correctOptionIndex");
      const scores = new Map<string, number>();
      for (const answer of answers.docs) {
        const isCorrect =
          answer.get("questionId") === questionId
            ? answer.get("selectedOptionIndex") === correct
            : answer.get("isCorrect") === true;
        if (answer.get("questionId") === questionId)
          tx.update(answer.ref, { isCorrect });
        if (isCorrect)
          scores.set(
            answer.get("teamId"),
            (scores.get(answer.get("teamId")) ?? 0) + 10,
          );
      }
      for (const team of teams.docs)
        tx.update(team.ref, { score: scores.get(team.id) ?? 0 });
      tx.update(questionRef, {
        status: "revealed",
        correctOptionIndex: correct,
        explanation: secret.get("explanation") ?? null,
      });
      return finish();
    }
    throw new HttpsError("invalid-argument", "未対応の操作です。");
  });
}
