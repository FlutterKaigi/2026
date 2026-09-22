const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { before, after, test } = require("node:test");
const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { administerEvent } = require("../lib/event_admin_service.js");

// These integration tests always use isolated emulator projects. They do not
// depend on a production account or grant the caller any target-project role.
const host = process.env.FIRESTORE_EMULATOR_HOST ?? "127.0.0.1:8080";
assert.match(host, /^(localhost|127\.0\.0\.1|\[::1\]):\d+$/);
process.env.FIRESTORE_EMULATOR_HOST = host;
const suffix = randomUUID().slice(0, 8);
const apps = ["source", "stg", "prod"].map((environment) =>
  initializeApp({ projectId: `demo-admin-${environment}-${suffix}` }, `admin-${environment}-${suffix}`));
const [source, stg, prod] = apps.map((app) => getFirestore(app));
const actor = { uid: "admin-only-in-source", token: { email: "admin@flutterkaigi.jp", email_verified: true } };
const getUser = async (uid) => { assert.equal(uid, actor.uid); return { disabled: false }; };
const deps = { adminDb: source, getUser, target: (environment) => {
  assert.ok(environment === "stg" || environment === "prod");
  return environment === "stg" ? stg : prod;
} };
const call = (environment, action, payload) => administerEvent(actor, { environment, action, payload }, deps);
const eventId = "identical-event-id";
const eventPayload = {
  eventId, title: { ja: "クイズ", en: "Quiz" }, capacity: 3, sponsorIds: ["sponsor"], teamNamePool: [],
};
const questionPayload = {
  eventId, questionId: "q1", question: {
    sponsorId: "sponsor", order: 1, title: { ja: "問題", en: "Question" },
    options: [{ ja: "正解", en: "Correct" }, { ja: "不正解", en: "Wrong" }], durationSeconds: 180,
  }, secret: { correctOptionIndex: 0, explanation: { ja: "解説", en: "Explanation" } },
};
const op = (operation, extra = {}) => call("prod", "quizOperation", {
  eventId, operation, operationId: randomUUID(), ...extra,
});

before(async () => { await source.doc(`admins/${actor.uid}`).set({}); });
after(async () => {
  for (const db of [source, stg, prod]) {
    for (const collection of await db.listCollections()) await db.recursiveDelete(collection);
  }
  await Promise.all(apps.map(deleteApp));
});

test("source authentication manages STG and production independently through the whole quiz lifecycle", async () => {
  await call("stg", "saveEvent", { ...eventPayload, title: { ja: "STG", en: "STG" } });
  await call("prod", "saveEvent", eventPayload);
  await call("prod", "saveQuestion", questionPayload);
  assert.equal((await stg.doc(`quizEvents/${eventId}/questions/q1`).get()).exists, false);
  assert.equal((await prod.doc(`admins/${actor.uid}`).get()).exists, false);

  const entry = await op("regenerateEntryCode");
  assert.match(entry.code, /^\d{6}$/);
  await op("publish");
  await op("openRegistration");
  for (let i = 0; i < 3; i++) {
    await prod.doc(`quizEvents/${eventId}/participants/member-${i}`).set({ displayName: `Member ${i}`, registeredAt: Timestamp.now() });
  }
  await prod.doc(`quizEvents/${eventId}`).update({ participantCount: 3 });
  await op("closeRegistration");
  await op("buildTeams");

  let snapshot = await call("prod", "read", { view: "quizConsole", eventId });
  assert.equal(snapshot.teams.length, 1);
  assert.equal(snapshot.participants.length, 3);
  assert.equal(snapshot.entryCode, entry.code);
  const teamId = snapshot.teams[0].id;
  await call("prod", "renameTeam", { eventId, teamId, name: "Selected production team" });
  await call("prod", "updateTeamNamePool", { eventId, names: ["One", "Two"] });
  await op("presentQuestion", { questionId: "q1" });

  const projection = await call("prod", "read", { view: "quizProjection", eventId });
  assert.equal(projection.question.status, "reading");
  assert.equal("entryCode" in projection, false);
  assert.equal("secret" in projection, false);
  assert.equal(projection.question.correctOptionIndex, undefined);
  await assert.rejects(call("prod", "saveQuestion", questionPayload), { code: "failed-precondition" });
  await assert.rejects(call("prod", "deleteQuestion", { eventId, questionId: "q1" }), { code: "failed-precondition" });
  await assert.rejects(call("prod", "saveEvent", eventPayload), { code: "failed-precondition" });

  await op("openQuestion", { questionId: "q1" });
  const extension = { eventId, operation: "extendQuestion", questionId: "q1", seconds: 30, operationId: randomUUID() };
  await call("prod", "quizOperation", extension);
  const extended = (await prod.doc(`quizEvents/${eventId}/questions/q1`).get()).get("closesAt").toMillis();
  await call("prod", "quizOperation", extension);
  assert.equal((await prod.doc(`quizEvents/${eventId}/questions/q1`).get()).get("closesAt").toMillis(), extended);
  await op("closeQuestion", { questionId: "q1" });
  await op("revealQuestion", { questionId: "q1" });
  await op("finalizeEvent");
  snapshot = await call("prod", "read", { view: "quizProjection", eventId });
  assert.equal(snapshot.event.status, "finished");
  assert.equal(snapshot.teams[0].name, "Selected production team");
  assert.equal(snapshot.teams[0].rank, 1);
  assert.equal((await stg.doc(`quizEvents/${eventId}`).get()).get("status"), "draft");
  assert.equal((await source.collection("quizEvents").get()).empty, true);
});

test("support LT issuance uses source admin identity and only changes the selected target", async () => {
  const first = await call("prod", "issueSupportLtCode", { rotate: false });
  assert.match(first.code, /^\d{6}$/);
  await prod.doc("supportLtRegistrations/person").set({ displayName: "本番参加者", registeredAt: Timestamp.now() });
  const rotated = await call("prod", "issueSupportLtCode", { rotate: true });
  assert.notEqual(rotated.code, first.code);
  const snapshot = await call("prod", "read", { view: "supportLt" });
  assert.equal(snapshot.registrations[0].displayName, "本番参加者");
  assert.equal(snapshot.code.issuedBy, actor.uid);
  assert.equal((await stg.doc("supportLtSettings/current").get()).exists, false);
  assert.equal((await source.doc("supportLtSettings/current").get()).exists, false);
});

test("revoking source admin access stops both environments, even when target data exists", async () => {
  await source.doc(`admins/${actor.uid}`).delete();
  try {
    for (const environment of ["stg", "prod"]) {
      await assert.rejects(call(environment, "read", { view: "supportLt" }), { code: "permission-denied" });
      await assert.rejects(call(environment, "issueSupportLtCode", { rotate: true }), { code: "permission-denied" });
    }
  } finally {
    await source.doc(`admins/${actor.uid}`).set({});
  }
});

async function rehearsal(label) {
  const id = `rehearsal-${label}-${randomUUID().slice(0, 8)}`;
  await call("stg", "saveEvent", { ...eventPayload, eventId: id });
  await call("stg", "saveQuestion", { ...questionPayload, eventId: id });
  await stg.doc(`quizEvents/${id}`).update({ status: "finished", isPublic: true, currentQuestionId: "q1", participantCount: 3 });
  await stg.doc(`quizEvents/${id}/questions/q1`).update({
    status: "revealed", correctOptionIndex: 0, explanation: { ja: "公開された解説", en: "Revealed" },
    openedAt: Timestamp.now(), closesAt: Timestamp.now(),
  });
  await Promise.all(["participants", "participantAccounts", "teams", "answers", "admissionSlots", "operations", "entryAttempts"].map(
    (name) => stg.doc(`quizEvents/${id}/${name}/test-data`).set({ testOnly: true }),
  ));
  await stg.doc(`quizEvents/${id}/secret/entry`).set({ code: "999999" });
  return id;
}

test("promotes only the reviewed event definition, with fresh private production state and safe retries", async () => {
  const sourceEventId = await rehearsal("selected");
  const otherSourceId = await rehearsal("not-selected");
  const targetId = `production-${randomUUID()}`;
  let preview = await call("stg", "previewQuizPromotion", { eventId: sourceEventId });
  assert.deepEqual(preview.missingSponsorIds, ["sponsor"]);
  const payload = { eventId: sourceEventId, revision: preview.revision, operationId: targetId };
  await assert.rejects(call("stg", "promoteQuizEvent", payload), { code: "failed-precondition" });
  assert.equal((await prod.doc(`quizEvents/${targetId}`).get()).exists, false);
  await prod.doc("sponsors/sponsor").set({ name: { ja: "本番スポンサー", en: "Production sponsor" } });
  preview = await call("stg", "previewQuizPromotion", { eventId: sourceEventId });
  assert.equal(preview.questionCount, 1);
  assert.deepEqual(preview.missingSponsorIds, []);
  await assert.rejects(call("stg", "promoteQuizEvent", { ...payload, revision: "stale" }), { code: "failed-precondition" });
  assert.deepEqual(await call("stg", "promoteQuizEvent", payload), { eventId: targetId });

  const copied = (await prod.doc(`quizEvents/${targetId}`).get()).data();
  assert.equal(copied.status, "draft");
  assert.equal(copied.isPublic, false);
  assert.equal(copied.currentQuestionId, null);
  assert.equal(copied.participantCount, 0);
  assert.equal(copied.promotion.sourceEventId, sourceEventId);
  assert.equal(copied.promotion.promotedBy, actor.uid);
  assert.equal((await prod.doc(`quizEvents/${otherSourceId}`).get()).exists, false);
  assert.equal((await prod.doc(`quizPromotions/${otherSourceId}`).get()).exists, false);
  for (const name of ["participants", "participantAccounts", "teams", "answers", "admissionSlots", "operations", "entryAttempts", "secret"]) {
    assert.equal((await prod.collection(`quizEvents/${targetId}/${name}`).get()).empty, true, name);
  }
  const question = (await prod.doc(`quizEvents/${targetId}/questions/q1`).get()).data();
  assert.equal(question.status, "draft");
  for (const field of ["correctOptionIndex", "explanation", "openedAt", "closesAt"]) assert.equal(field in question, false, field);
  assert.equal((await prod.doc(`quizEvents/${targetId}/questions/q1/secret/answer`).get()).get("correctOptionIndex"), 0);
  assert.equal((await prod.doc(`quizEvents/${eventId}`).get()).get("status"), "finished", "Unrelated production event is untouched");

  // An ambiguous-response retry is idempotent even after STG or prod was edited.
  await prod.doc(`quizEvents/${targetId}`).update({ title: { ja: "本番で修正", en: "Edited in production" } });
  await stg.doc(`quizEvents/${sourceEventId}`).update({ title: { ja: "STG で修正", en: "Edited in STG" } });
  assert.deepEqual(await call("stg", "promoteQuizEvent", payload), { eventId: targetId });
  assert.equal((await prod.doc(`quizEvents/${targetId}`).get()).get("title.ja"), "本番で修正");
  const latest = await call("stg", "previewQuizPromotion", { eventId: sourceEventId });
  assert.equal(latest.existingEventId, targetId);
  await assert.rejects(call("stg", "promoteQuizEvent", { ...payload, revision: latest.revision, operationId: randomUUID() }), { code: "failed-precondition" });

  // Withdrawal archives exactly this copy. Retrying the old import cannot restore it.
  await call("prod", "withdrawQuizPromotion", { eventId: targetId });
  await call("prod", "withdrawQuizPromotion", { eventId: targetId });
  assert.equal((await prod.doc(`quizEvents/${targetId}`).get()).get("promotionWithdrawn"), true);
  assert.equal((await prod.doc(`quizEvents/${targetId}/questions/q1/secret/answer`).get()).exists, true);
  assert.equal((await call("prod", "read", { view: "quizEvents" })).events.some((e) => e.id === targetId), false);
  assert.equal((await call("prod", "read", { view: "quizConsole", eventId: targetId })).event, null);
  await assert.rejects(call("stg", "promoteQuizEvent", payload), { code: "failed-precondition" });
  await assert.rejects(call("prod", "quizOperation", { eventId: targetId, operation: "publish", operationId: randomUUID() }), { code: "failed-precondition" });
  await assert.rejects(call("prod", "saveEvent", { ...eventPayload, eventId: targetId }), { code: "failed-precondition" });
  const nextId = randomUUID();
  const next = await call("stg", "previewQuizPromotion", { eventId: sourceEventId });
  assert.equal(next.existingEventId, null);
  await call("stg", "promoteQuizEvent", { eventId: sourceEventId, revision: next.revision, operationId: nextId });
  assert.equal((await prod.doc(`quizEvents/${nextId}`).get()).get("title.ja"), "STG で修正");
  assert.equal((await stg.doc(`quizEvents/${sourceEventId}`).get()).get("status"), "finished");
  assert.equal((await prod.doc(`quizEvents/${targetId}`).get()).get("promotionWithdrawn"), true);
});

test("preview changes and concurrent promotions cannot overwrite or duplicate a production event", async () => {
  const sourceEventId = await rehearsal("concurrent");
  const initial = await call("stg", "previewQuizPromotion", { eventId: sourceEventId });
  await stg.doc(`quizEvents/${sourceEventId}/questions/q1/secret/answer`).update({ correctOptionIndex: 1 });
  await assert.rejects(call("stg", "promoteQuizEvent", {
    eventId: sourceEventId, revision: initial.revision, operationId: randomUUID(),
  }), { code: "failed-precondition" });
  const preview = await call("stg", "previewQuizPromotion", { eventId: sourceEventId });
  const ids = [randomUUID(), randomUUID()];
  const results = await Promise.allSettled(ids.map((operationId) => call("stg", "promoteQuizEvent", {
    eventId: sourceEventId, revision: preview.revision, operationId,
  })));
  assert.equal(results.filter((result) => result.status === "fulfilled").length, 1);
  assert.equal((await prod.getAll(...ids.map((id) => prod.doc(`quizEvents/${id}`)))).filter((doc) => doc.exists).length, 1);
});

test("published imports can be withdrawn, but registration or attendee data prevents withdrawal", async () => {
  for (const activity of ["none", "registration", "participant"]) {
    const sourceEventId = await rehearsal(activity);
    const preview = await call("stg", "previewQuizPromotion", { eventId: sourceEventId });
    const id = randomUUID();
    await call("stg", "promoteQuizEvent", { eventId: sourceEventId, revision: preview.revision, operationId: id });
    const operate = (operation) => call("prod", "quizOperation", { eventId: id, operation, operationId: randomUUID() });
    await operate("publish");
    if (activity === "registration") {
      await operate("regenerateEntryCode");
      await operate("openRegistration");
    }
    if (activity === "participant") await prod.doc(`quizEvents/${id}/participants/person`).set({ displayName: "Real attendee" });
    if (activity === "none") {
      await call("prod", "withdrawQuizPromotion", { eventId: id });
      assert.equal((await prod.doc(`quizEvents/${id}`).get()).get("isPublic"), false);
    } else {
      await assert.rejects(call("prod", "withdrawQuizPromotion", { eventId: id }), { code: "failed-precondition" });
      assert.equal((await prod.doc(`quizEvents/${id}`).get()).get("isPublic"), true);
    }
  }
});

test("withdrawal racing registration cannot hide an event that has begun admitting attendees", async () => {
  const sourceEventId = await rehearsal("withdrawal-race");
  const preview = await call("stg", "previewQuizPromotion", { eventId: sourceEventId });
  const id = randomUUID();
  await call("stg", "promoteQuizEvent", { eventId: sourceEventId, revision: preview.revision, operationId: id });
  const operate = (operation) => call("prod", "quizOperation", { eventId: id, operation, operationId: randomUUID() });
  await operate("publish");
  await operate("regenerateEntryCode");
  const results = await Promise.allSettled([
    call("prod", "withdrawQuizPromotion", { eventId: id }), operate("openRegistration"),
  ]);
  assert.equal(results.filter((result) => result.status === "fulfilled").length, 1);
  const event = (await prod.doc(`quizEvents/${id}`).get()).data();
  if (event.promotionWithdrawn === true) {
    assert.equal(event.isPublic, false);
    assert.equal(event.status, "draft");
    assert.notEqual(event.admissionSlotsReady, true);
  } else {
    assert.equal(event.status, "registration");
    assert.equal(event.isPublic, true);
    assert.equal(event.admissionSlotsReady, true);
  }
});
