const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { before, after, test } = require("node:test");
const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const {
  operateQuizEvent, registerQuizParticipantForUser, checkInQuizParticipantForUser, selectQuizTeamForUser,
} = require("../lib/quiz_service.js");
const { deleteQuizEvent } = require("../lib/quiz_deletion_service.js");

const host = process.env.FIRESTORE_EMULATOR_HOST ?? "127.0.0.1:8080";
assert.match(host, /^(localhost|127\.0\.0\.1|\[::1\]):\d+$/);
process.env.FIRESTORE_EMULATOR_HOST = host;
const app = initializeApp({ projectId: `demo-quiz-unpublish-${randomUUID().slice(0, 8)}` }, `unpublish-${randomUUID()}`);
const db = getFirestore(app);
const admin = { uid: "administrator", token: { email: "admin@flutterkaigi.jp", email_verified: true } };
const user = (label) => ({ uid: `${label}-${randomUUID()}`, token: { firebase: { sign_in_provider: "password" } } });
const dependencies = { db, getUser: async (uid) => ({ disabled: false, email: `${uid}@example.test`, displayName: uid }) };
const op = (eventId, operation, extra = {}) => operateQuizEvent(admin, { eventId, operation, operationId: randomUUID(), ...extra }, db);
const register = (eventId, actor) => registerQuizParticipantForUser(actor, { eventId }, dependencies);
const checkIn = (eventId, actor, code) => checkInQuizParticipantForUser(actor, { eventId, code }, dependencies);
const select = (eventId, actor, teamId, expectedTeamId = null) => selectQuizTeamForUser(actor, { eventId, teamId, expectedTeamId }, db);

before(async () => { await db.doc(`admins/${admin.uid}`).set({}); });
after(async () => {
  for (const collection of await db.listCollections()) await db.recursiveDelete(collection);
  await deleteApp(app);
});

async function seedEvent(status = "registration") {
  const ref = db.doc(`quizEvents/${randomUUID()}`);
  const now = Timestamp.now();
  await ref.set({
    title: { ja: "クイズ", en: "Quiz" }, status, isPublic: status !== "draft", capacity: 10,
    sponsorIds: ["sponsor"], teamNamePool: [], currentQuestionId: null, createdAt: now, updatedAt: now,
  });
  await ref.collection("questions").doc("q1").set({
    status: "draft", sponsorId: "sponsor", order: 1, title: { ja: "問題", en: "Question" },
    options: [{ ja: "A", en: "A" }, { ja: "B", en: "B" }], durationSeconds: 180,
  });
  await ref.collection("questions").doc("q1").collection("secret").doc("answer").set({ correctOptionIndex: 0 });
  if (status === "registration") await op(ref.id, "openRegistration");
  return ref;
}

async function eventRecords(ref) {
  const records = {};
  async function collect(document) {
    for (const collection of await document.listCollections()) {
      if (collection.id === "operations") continue;
      for (const snapshot of (await collection.get()).docs) {
        records[snapshot.ref.path] = snapshot.data();
        await collect(snapshot.ref);
      }
    }
  }
  await collect(ref);
  return records;
}

function retainedEventFields(data) {
  const { status, isPublic, updatedAt, revision, ...retained } = data;
  return retained;
}

test("only administrators can stop reception and unpublish", async () => {
  const ref = await seedEvent();
  for (const [actor, code] of [
    [undefined, "unauthenticated"],
    [user("attendee"), "permission-denied"],
    [{ ...admin, uid: "organization-member" }, "permission-denied"],
    [{ ...admin, token: { ...admin.token, email_verified: false } }, "permission-denied"],
  ]) {
    await assert.rejects(operateQuizEvent(actor, { eventId: ref.id, operation: "unpublish", operationId: randomUUID() }, db), { code });
    assert.equal((await ref.get()).get("status"), "registration");
  }
  await op(ref.id, "unpublish");
  assert.equal((await ref.get()).get("status"), "draft");
});

test("unpublishing reception preserves all records and locks until explicit reopening", async () => {
  for (const status of ["registration", "entryClosed"]) {
    const ref = await seedEvent();
    const selected = user("selected"), unchecked = user("unchecked"), unselected = user("unselected"), newcomer = user("newcomer");
    for (const actor of [selected, unchecked, unselected]) await register(ref.id, actor);
    await op(ref.id, "closeRegistration");
    await op(ref.id, "openTeamSelection");
    const code = (await ref.collection("secret").doc("checkIn").get()).get("code");
    await checkIn(ref.id, selected, code);
    await checkIn(ref.id, unselected, code);
    await select(ref.id, selected, "A");
    // Older retained records are deliberately present: hiding must never
    // initialize or clear teams, answers, entry attempts, or check-in attempts.
    for (const name of ["teams", "answers", "entryClaims", "entryAttempts", "checkInAttempts"]) {
      await ref.collection(name).doc("retained-record").set({ value: "keep", recordedAt: Timestamp.now() });
    }
    if (status === "registration") await op(ref.id, "reopenRegistration");
    const beforeEvent = (await ref.get()).data();
    const beforeRecords = await eventRecords(ref);
    const locks = await db.getAll(...[selected, unchecked, unselected].map((actor) => db.doc(`quizParticipation/${actor.uid}`)));
    const operationId = randomUUID();
    await op(ref.id, "unpublish", { operationId });
    const hidden = (await ref.get()).data();
    assert.equal(hidden.status, "draft");
    assert.equal(hidden.isPublic, false);
    assert.deepEqual(retainedEventFields(hidden), retainedEventFields(beforeEvent));
    assert.deepEqual(await eventRecords(ref), beforeRecords);
    for (const lock of locks) assert.deepEqual((await lock.ref.get()).data(), lock.data());
    await op(ref.id, "unpublish", { operationId });
    assert.deepEqual((await ref.get()).data(), hidden, "The same operation ID must not write a second transition");
    await assert.rejects(register(ref.id, newcomer), { code: "failed-precondition" });
    await assert.rejects(checkIn(ref.id, unchecked, code), { code: "failed-precondition" });
    await assert.rejects(select(ref.id, selected, "B", "A"), { code: "failed-precondition" });
    await assert.rejects(select(ref.id, unselected, "C"), { code: "failed-precondition" });
    for (const operation of ["openRegistration", "reopenRegistration", "openTeamSelection", "regenerateCheckInCode"]) {
      await assert.rejects(op(ref.id, operation), { code: "failed-precondition" });
    }
    // Lost acknowledgements for already committed work remain harmless.
    await register(ref.id, selected);
    await checkIn(ref.id, selected, code);
    await select(ref.id, selected, "A", "A");
    assert.deepEqual(await eventRecords(ref), beforeRecords);
    const other = await seedEvent();
    await assert.rejects(register(other.id, selected), { code: "already-exists" });

    await op(ref.id, "publish");
    assert.equal((await ref.get()).get("status"), "published");
    assert.equal((await ref.get()).get("isPublic"), true);
    await assert.rejects(deleteQuizEvent(db, { eventId: ref.id }, admin.uid), { code: "failed-precondition" });
    await assert.rejects(register(ref.id, newcomer), { code: "failed-precondition" });
    await assert.rejects(checkIn(ref.id, unchecked, code), { code: "failed-precondition" });
    await assert.rejects(select(ref.id, selected, "B", "A"), { code: "failed-precondition" });
    await op(ref.id, "unpublish", { operationId });
    assert.equal((await ref.get()).get("status"), "published", "An old retry cannot undo a later publication");
    assert.deepEqual(await eventRecords(ref), beforeRecords);
    await op(ref.id, "openRegistration");
    assert.equal((await ref.get()).get("status"), "registration");
    assert.equal((await ref.collection("secret").doc("checkIn").get()).get("code"), code);
    await register(ref.id, newcomer);
    await checkIn(ref.id, unchecked, code);
    await select(ref.id, unselected, "C");
    for (const lock of locks) assert.deepEqual((await lock.ref.get()).data(), lock.data());
  }
});

test("unpublishing refuses any evidence that questions have started", async () => {
  const scenarios = [
    { status: "inProgress" }, { status: "finished" },
    { status: "registration", currentQuestionId: "q1" },
    ...["reading", "open", "closed", "revealed"].map((questionStatus) => ({ status: "entryClosed", questionStatus })),
    { status: "draft", questionStatus: "revealed" },
  ];
  for (const scenario of scenarios) {
    const ref = await seedEvent(scenario.status);
    if (scenario.currentQuestionId) await ref.update({ currentQuestionId: scenario.currentQuestionId });
    if (scenario.questionStatus) await ref.collection("questions").doc("q1").update({ status: scenario.questionStatus });
    const original = (await ref.get()).data();
    const records = await eventRecords(ref);
    await assert.rejects(op(ref.id, "unpublish"), { code: "failed-precondition" }, JSON.stringify(scenario));
    assert.deepEqual((await ref.get()).data(), original);
    assert.deepEqual(await eventRecords(ref), records);
  }
  for (const status of ["draft", "published"]) {
    const ref = await seedEvent(status);
    await op(ref.id, "unpublish");
    assert.equal((await ref.get()).get("status"), "draft");
    assert.equal((await ref.get()).get("isPublic"), false);
  }
});

test("a registration racing unpublish either commits intact before closure or is rejected", async () => {
  const ref = await seedEvent();
  const actor = user("arrival");
  const [hidden, registration] = await Promise.allSettled([op(ref.id, "unpublish"), register(ref.id, actor)]);
  assert.equal(hidden.status, "fulfilled");
  assert.equal((await ref.get()).get("status"), "draft");
  const participant = await ref.collection("participants").doc(actor.uid).get();
  const account = await ref.collection("participantAccounts").doc(actor.uid).get();
  const lock = await db.doc(`quizParticipation/${actor.uid}`).get();
  const slots = await ref.collection("admissionSlots").where("uid", "==", actor.uid).get();
  const admitted = registration.status === "fulfilled";
  assert.equal(participant.exists, admitted);
  assert.equal(account.exists, admitted);
  assert.equal(lock.exists, admitted);
  assert.equal(slots.size, admitted ? 1 : 0);
  await assert.rejects(register(ref.id, user("late-arrival")), { code: "failed-precondition" });
});

test("publication and reopening races never silently reopen a hidden reception", async () => {
  const published = await seedEvent("published");
  const results = await Promise.allSettled([op(published.id, "unpublish"), op(published.id, "openRegistration")]);
  assert.equal(results[0].status, "fulfilled");
  assert.equal((await published.get()).get("status"), "draft");
  assert.equal((await published.get()).get("isPublic"), false);

  const registering = await seedEvent();
  const competing = await Promise.allSettled([op(registering.id, "unpublish"), op(registering.id, "publish")]);
  assert.equal(competing[0].status, "fulfilled");
  const event = (await registering.get()).data();
  assert.equal(event.status, competing[1].status === "fulfilled" ? "published" : "draft");
  assert.equal(event.isPublic, event.status === "published");
  await assert.rejects(register(registering.id, user("still-closed")), { code: "failed-precondition" });
});

test("unpublishing and starting the first question cannot both commit", async () => {
  const ref = await seedEvent();
  const actor = user("ready");
  await register(ref.id, actor);
  await op(ref.id, "closeRegistration");
  await op(ref.id, "openTeamSelection");
  const code = (await ref.collection("secret").doc("checkIn").get()).get("code");
  await checkIn(ref.id, actor, code);
  await select(ref.id, actor, "A");
  await op(ref.id, "closeTeamSelection");
  const participant = (await ref.collection("participants").doc(actor.uid).get()).data();
  const results = await Promise.allSettled([
    op(ref.id, "unpublish"), op(ref.id, "presentQuestion", { questionId: "q1" }),
  ]);
  assert.equal(results.filter((result) => result.status === "fulfilled").length, 1);
  const event = (await ref.get()).data();
  const question = (await ref.collection("questions").doc("q1").get()).data();
  if (results[0].status === "fulfilled") {
    assert.equal(event.status, "draft");
    assert.equal(event.isPublic, false);
    assert.equal(question.status, "draft");
  } else {
    assert.equal(event.status, "inProgress");
    assert.equal(event.isPublic, true);
    assert.equal(question.status, "reading");
  }
  assert.deepEqual((await ref.collection("participants").doc(actor.uid).get()).data(), participant);
  assert.equal((await db.doc(`quizParticipation/${actor.uid}`).get()).get("eventId"), ref.id);
});
