const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { before, after, test } = require("node:test");
const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { administerEvent } = require("../lib/event_admin_service.js");
const { deleteAuthUserData } = require("../lib/auth_user_data.js");
const {
  registerQuizParticipantForUser, checkInQuizParticipantForUser, selectQuizTeamForUser, submitQuizAnswerForUser,
} = require("../lib/quiz_service.js");

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
const participant = (uid) => ({ uid, token: { firebase: { sign_in_provider: "password" } } });
const participantDeps = { db: prod, getUser: async (uid) => ({ uid, disabled: false, email: `${uid}@example.test` }) };
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
  // Projection names sponsors from the selected project, in the console's shape.
  await stg.doc("sponsors/sponsor").set({ name: { ja: "STGスポンサー", en: "STG sponsor" } });
  const stgProjection = await call("stg", "read", { view: "quizProjection", eventId });
  assert.deepEqual(stgProjection.sponsors, [{ id: "sponsor", name: { ja: "STGスポンサー", en: "STG sponsor" } }]);
  assert.deepEqual(stgProjection.sponsors, (await call("stg", "read", { view: "quizConsole", eventId })).sponsors);
  assert.deepEqual((await call("prod", "read", { view: "quizProjection", eventId })).sponsors, []);

  await op("publish");
  await op("openRegistration");
  for (let i = 0; i < 3; i++) {
    await prod.doc(`quizEvents/${eventId}/participants/member-${i}`).set({ displayName: `Member ${i}`, registeredAt: Timestamp.now() });
  }
  await prod.doc(`quizEvents/${eventId}`).update({ participantCount: 3 });
  await op("closeRegistration");
  await op("openTeamSelection");
  const checkInProjection = await call("prod", "read", { view: "quizProjection", eventId });
  assert.match(checkInProjection.checkInCode, /^\d{6}$/);
  for (let i = 0; i < 3; i++) await prod.doc(`quizEvents/${eventId}/participants/member-${i}`).update({ teamId: "A" });
  await op("closeTeamSelection");
  assert.equal((await call("prod", "read", { view: "quizProjection", eventId })).checkInCode, null);
  let snapshot = await call("prod", "read", { view: "quizConsole", eventId });
  assert.equal(snapshot.teams.length, 0);
  assert.equal(snapshot.participants.length, 3);
  assert.equal(snapshot.checkInCode, checkInProjection.checkInCode);
  assert.equal("entryCode" in snapshot, false);
  for (const action of ["renameTeam", "updateTeamNamePool"]) {
    await assert.rejects(call("prod", action, { eventId, teamId: "A", name: "Changed", names: ["Changed"] }), { code: "invalid-argument" });
  }
  await call("prod", "saveEvent", { ...eventPayload, teamSelectionStatus: "open" });
  assert.equal((await prod.doc(`quizEvents/${eventId}`).get()).get("teamSelectionStatus"), "closed");
  await op("presentQuestion", { questionId: "q1" });

  const projection = await call("prod", "read", { view: "quizProjection", eventId });
  assert.equal(projection.question.status, "reading");
  assert.equal(projection.checkInCode, null);
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
  assert.equal(snapshot.teams[0].name, "A");
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
  await stg.doc(`quizEvents/${id}`).update({ status: "finished", isPublic: true, currentQuestionId: "q1", participantCount: 3, teamSelectionStatus: "closed" });
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
  assert.equal(copied.teamSelectionStatus, undefined);
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

async function draft(label) {
  const id = `${label}-${randomUUID()}`;
  await call("prod", "saveEvent", { ...eventPayload, eventId: id });
  await call("prod", "saveQuestion", { ...questionPayload, eventId: id });
  return id;
}

test("only an active source administrator can delete a private event", async () => {
  const id = await draft("deletion-auth");
  const request = { environment: "prod", action: "deleteEvent", payload: { eventId: id } };
  for (const [auth, getUser, code] of [
    [undefined, async () => ({ disabled: false }), "unauthenticated"],
    [{ uid: "attendee", token: { email: "attendee@example.test", email_verified: true } }, async () => ({ disabled: false }), "permission-denied"],
    [{ ...actor, uid: "organization-member" }, async () => ({ disabled: false }), "permission-denied"],
    [actor, async () => ({ disabled: true }), "permission-denied"],
  ]) {
    await assert.rejects(administerEvent(auth, request, { ...deps, getUser }), { code });
    assert.equal((await prod.doc(`quizEvents/${id}`).get()).exists, true);
    assert.equal((await prod.doc(`quizEventDeletions/${id}`).get()).exists, false);
  }
  await call("prod", "deleteEvent", { eventId: id });
  assert.equal((await prod.doc(`quizEvents/${id}`).get()).exists, false);
});

test("deleting a draft removes its whole tree and permanently rejects stale saves", async () => {
  const id = await draft("delete-tree");
  const other = await draft("keep-tree");
  await prod.doc(`quizEvents/${id}`).update({ teamSelectionStatus: "notStarted" });
  await call("stg", "saveEvent", { ...eventPayload, eventId: id });
  const nested = prod.doc(`quizEvents/${id}/questions/q1/secret/answer/audit/extra`);
  await nested.set({ value: "nested secret" });
  const orphan = prod.doc(`quizEvents/${id}/questions/missing/secret/answer`);
  await orphan.set({ value: "orphaned descendant" });
  const operate = (operation) => call("prod", "quizOperation", { eventId: id, operation, operationId: randomUUID() });
  await operate("publish");
  await operate("unpublish");
  assert.deepEqual(await call("prod", "deleteEvent", { eventId: id }), { eventId: id });
  assert.deepEqual(await call("prod", "deleteEvent", { eventId: id }), { eventId: id });
  assert.equal((await prod.doc(`quizEvents/${id}`).get()).exists, false);
  assert.deepEqual(await prod.doc(`quizEvents/${id}`).listCollections(), []);
  assert.equal((await nested.get()).exists, false);
  assert.equal((await orphan.get()).exists, false);
  assert.equal((await prod.doc(`quizEvents/${other}/questions/q1/secret/answer`).get()).exists, true);
  assert.equal((await stg.doc(`quizEvents/${id}`).get()).exists, true);
  assert.equal((await prod.doc("sponsors/sponsor").get()).exists, true);
  assert.equal((await prod.doc(`quizEventDeletions/${id}`).get()).get("status"), "deleted");
  assert.equal((await prod.doc(`quizEventDeletions/${id}`).get()).get("event"), undefined);
  await assert.rejects(call("prod", "saveEvent", { ...eventPayload, eventId: id }), { code: "failed-precondition" });
  await assert.rejects(call("prod", "saveQuestion", { ...questionPayload, eventId: id }), { code: "failed-precondition" });
  await assert.rejects(operate("publish"), { code: "failed-precondition" });
  await assert.rejects(call("prod", "deleteEvent", { eventId: "missing-event" }), { code: "not-found" });
});

test("deletion requires an explicitly private event in every lifecycle state", async () => {
  const cases = [
    ...["draft", "published", "registration", "entryClosed", "inProgress", "finished"]
      .map((status) => ({ status, isPublic: true })),
    { status: "draft" }, { status: "draft", isPublic: null }, { status: "draft", isPublic: "false" },
  ];
  for (const fields of cases) {
    const id = await draft("public-protected");
    const ref = prod.doc(`quizEvents/${id}`);
    await ref.set(fields);
    await assert.rejects(call("prod", "deleteEvent", { eventId: id }), { code: "failed-precondition" });
    assert.deepEqual((await ref.get()).data(), fields);
    assert.equal((await ref.collection("questions").doc("q1").get()).exists, true);
    assert.equal((await prod.doc(`quizEventDeletions/${id}`).get()).exists, false);
  }
});

test("private events can be deleted with participants and results in every lifecycle state", async () => {
  const other = await draft("keep-other-event");
  const otherLock = prod.doc(`quizParticipation/${other}-member`);
  const otherLockData = { eventId: other, registeredAt: Timestamp.now() };
  await otherLock.set(otherLockData);
  for (const status of ["draft", "published", "registration", "entryClosed", "inProgress", "finished"]) {
    const id = await draft(`private-${status}`);
    const ref = prod.doc(`quizEvents/${id}`);
    await ref.update({ status, isPublic: false, admissionSlotsReady: true, participantCount: 3,
      currentQuestionId: "q1", teamSelectionStatus: "closed" });
    await ref.collection("questions").doc("q1").update({ status: "revealed" });
    await ref.collection("teams").doc("A").set({ score: 10, rank: 1, perfectSponsorIds: ["sponsor"] });
    for (const name of ["participants", "participantAccounts", "answers", "admissionSlots", "entryClaims", "entryAttempts", "checkInAttempts", "operations", "secret"]) {
      await ref.collection(name).doc("record").set({ value: "remove" });
    }
    const active = prod.doc(`quizParticipation/${id}-active`);
    const deleted = prod.doc(`quizParticipation/${id}-deleted`);
    await active.set({ eventId: id, registeredAt: Timestamp.now() });
    await deleted.set({ eventId: id, registeredAt: Timestamp.now(), accountDeleted: true });
    await call("prod", "deleteEvent", { eventId: id });
    assert.equal((await ref.get()).exists, false);
    assert.deepEqual(await ref.listCollections(), []);
    assert.equal((await active.get()).exists, false);
    assert.deepEqual((await deleted.get()).data(), { accountDeleted: true });
    assert.equal((await prod.doc(`quizEventDeletions/${id}`).get()).get("status"), "deleted");
    assert.deepEqual((await otherLock.get()).data(), otherLockData);
    assert.equal((await prod.doc(`quizEvents/${other}/questions/q1/secret/answer`).get()).exists, true);
  }
});

test("a reception event can be deleted after unpublishing with or without cancelling its participants", async () => {
  for (const cancel of [false, true]) {
    const id = await draft("delete-after-reception");
    const ref = prod.doc(`quizEvents/${id}`);
    const person = participant(`${id}-member`);
    const operate = (operation, extra = {}) => call("prod", "quizOperation", { eventId: id, operation, operationId: randomUUID(), ...extra });
    await operate("publish");
    await operate("openRegistration");
    await registerQuizParticipantForUser(person, { eventId: id }, participantDeps);
    await operate("closeRegistration");
    await operate("openTeamSelection");
    const code = (await ref.collection("secret").doc("checkIn").get()).get("code");
    await checkInQuizParticipantForUser(person, { eventId: id, code }, participantDeps);
    await selectQuizTeamForUser(person, { eventId: id, teamId: "A", expectedTeamId: null }, prod);
    await ref.collection("entryAttempts").doc(person.uid).set({ count: 1 });
    if (cancel) await operate("removeParticipant", { uid: person.uid });
    await operate("unpublish");
    assert.equal((await ref.get()).get("admissionSlotsReady"), true);
    assert.equal((await ref.collection("participants").get()).size, cancel ? 0 : 1);
    await call("prod", "deleteEvent", { eventId: id });
    assert.equal((await ref.get()).exists, false);
    assert.deepEqual(await ref.listCollections(), []);
    assert.equal((await prod.doc(`quizParticipation/${person.uid}`).get()).exists, false);
    const next = await draft("next-registration");
    await prod.doc(`quizEvents/${next}`).update({ status: "registration", isPublic: true });
    await registerQuizParticipantForUser(person, { eventId: next }, participantDeps);
    assert.equal((await prod.doc(`quizParticipation/${person.uid}`).get()).get("eventId"), next);
  }
});

test("a deleted production import can be promoted anew without resurrecting old requests", async () => {
  const sourceEventId = await rehearsal("delete-promotion");
  const preview = await call("stg", "previewQuizPromotion", { eventId: sourceEventId });
  const payload = { eventId: sourceEventId, revision: preview.revision, operationId: randomUUID() };
  await call("stg", "promoteQuizEvent", payload);
  await call("prod", "deleteEvent", { eventId: payload.operationId });
  const record = (await prod.doc(`quizPromotions/${sourceEventId}`).get()).data();
  assert.equal(record.status, "deleted");
  assert.equal(record.eventId, undefined);
  assert.equal(record.deletedEventId, payload.operationId);
  await assert.rejects(call("stg", "promoteQuizEvent", payload), { code: "failed-precondition" });
  assert.equal((await call("stg", "previewQuizPromotion", { eventId: sourceEventId })).existingEventId, null);
  const next = { ...payload, operationId: randomUUID() };
  await call("stg", "promoteQuizEvent", next);
  await call("prod", "deleteEvent", { eventId: payload.operationId });
  assert.equal((await prod.doc(`quizPromotions/${sourceEventId}`).get()).get("eventId"), next.operationId);
  assert.equal((await prod.doc(`quizEvents/${next.operationId}/questions/q1/secret/answer`).get()).exists, true);
  assert.equal((await stg.doc(`quizEvents/${sourceEventId}/participants/test-data`).get()).exists, true);
  // An older withdrawn copy may be deleted after a newer import already owns
  // the source's promotion record. That record must continue pointing at it.
  await call("prod", "withdrawQuizPromotion", { eventId: next.operationId });
  const newest = { ...payload, operationId: randomUUID() };
  await call("stg", "promoteQuizEvent", newest);
  await call("prod", "deleteEvent", { eventId: next.operationId });
  assert.equal((await prod.doc(`quizPromotions/${sourceEventId}`).get()).get("eventId"), newest.operationId);
  assert.equal((await prod.doc(`quizEvents/${newest.operationId}/questions/q1/secret/answer`).get()).exists, true);
});

test("partial recursive cleanup remains listed and a retry completes it without allowing edits", async () => {
  const id = await draft("delete-retry");
  const partialDb = new Proxy(prod, { get(target, name) {
    if (name === "recursiveDelete") return async (ref) => {
      await ref.collection("questions").doc("q1").delete();
      throw new Error("simulated interrupted cleanup");
    };
    const value = Reflect.get(target, name, target);
    return typeof value === "function" ? value.bind(target) : value;
  } });
  await assert.rejects(administerEvent(actor, { environment: "prod", action: "deleteEvent", payload: { eventId: id } }, {
    ...deps, target: () => partialDb,
  }), /simulated interrupted cleanup/);
  assert.equal((await prod.doc(`quizEvents/${id}`).get()).exists, false);
  assert.equal((await prod.doc(`quizEvents/${id}/questions/q1/secret/answer`).get()).exists, true);
  const pending = (await call("prod", "read", { view: "quizEvents" })).events.find((event) => event.id === id);
  assert.equal(pending.deletionPending, true);
  assert.equal(pending.title.ja, eventPayload.title.ja);
  await assert.rejects(call("prod", "saveEvent", { ...eventPayload, eventId: id }), { code: "failed-precondition" });
  await call("prod", "deleteEvent", { eventId: id });
  assert.deepEqual(await prod.doc(`quizEvents/${id}`).listCollections(), []);
  assert.equal((await call("prod", "read", { view: "quizEvents" })).events.some((event) => event.id === id), false);
});

test("deletion racing publication or edits cannot remove a published event or leave orphaned changes", async () => {
  const publishingId = await draft("delete-publish-race");
  const published = await Promise.allSettled([
    call("prod", "deleteEvent", { eventId: publishingId }),
    call("prod", "quizOperation", { eventId: publishingId, operation: "publish", operationId: randomUUID() }),
  ]);
  assert.equal(published.filter((result) => result.status === "fulfilled").length, 1);
  const publishedEvent = await prod.doc(`quizEvents/${publishingId}`).get();
  if (publishedEvent.exists) {
    assert.equal(publishedEvent.get("status"), "published");
    assert.equal((await prod.doc(`quizEventDeletions/${publishingId}`).get()).exists, false);
  } else {
    assert.deepEqual(await prod.doc(`quizEvents/${publishingId}`).listCollections(), []);
  }
  const editingId = await draft("delete-edit-race");
  const results = await Promise.allSettled([
    call("prod", "deleteEvent", { eventId: editingId }),
    call("prod", "saveQuestion", { ...questionPayload, eventId: editingId, questionId: "new-question" }),
    call("prod", "saveEvent", { ...eventPayload, eventId: editingId, title: { ja: "変更", en: "Changed" } }),
    call("prod", "deleteEvent", { eventId: editingId }),
  ]);
  assert.equal(results[0].status, "fulfilled");
  assert.equal(results[3].status, "fulfilled");
  assert.equal((await prod.doc(`quizEvents/${editingId}`).get()).exists, false);
  assert.deepEqual(await prod.doc(`quizEvents/${editingId}`).listCollections(), []);
  await assert.rejects(call("prod", "saveEvent", { ...eventPayload, eventId: editingId }), { code: "failed-precondition" });
});


test("partial participation cleanup resumes in pages and preserves moved locks and deleted-account markers", async () => {
  const id = await draft("delete-lock-retry");
  const other = await draft("moved-lock-target");
  const batch = prod.batch();
  for (let index = 0; index < 202; index++) {
    batch.set(prod.doc(`quizParticipation/${id}-bulk-${String(index).padStart(3, "0")}`), { eventId: id, registeredAt: Timestamp.now() });
  }
  const moved = prod.doc(`quizParticipation/${id}-z-moved`);
  const deleted = prod.doc(`quizParticipation/${id}-z-deleted`);
  for (const ref of [moved, deleted]) batch.set(ref, { eventId: id, registeredAt: Timestamp.now() });
  await batch.commit();
  let transactions = 0;
  const partialDb = new Proxy(prod, { get(target, name) {
    if (name === "runTransaction") return (...args) => {
      if (++transactions === 3) throw new Error("simulated participation cleanup interruption");
      return target.runTransaction(...args);
    };
    const value = Reflect.get(target, name, target);
    return typeof value === "function" ? value.bind(target) : value;
  } });
  await assert.rejects(administerEvent(actor, { environment: "prod", action: "deleteEvent", payload: { eventId: id } }, {
    ...deps, target: () => partialDb,
  }), /simulated participation cleanup interruption/);
  assert.deepEqual(await prod.doc(`quizEvents/${id}`).listCollections(), []);
  assert.equal((await prod.collection("quizParticipation").where("eventId", "==", id).get()).size, 4);
  assert.equal((await prod.doc(`quizEventDeletions/${id}`).get()).get("status"), "deleting");
  assert.equal((await call("prod", "read", { view: "quizEvents" })).events.find((event) => event.id === id).deletionPending, true);
  const movedData = { eventId: other, registeredAt: Timestamp.now() };
  await moved.set(movedData);
  await deleteAuthUserData(deleted.id, prod);
  await call("prod", "deleteEvent", { eventId: id });
  await call("prod", "deleteEvent", { eventId: id });
  assert.equal((await prod.collection("quizParticipation").where("eventId", "==", id).get()).empty, true);
  assert.deepEqual((await moved.get()).data(), movedData);
  assert.deepEqual((await deleted.get()).data(), { accountDeleted: true });
  assert.equal((await prod.doc(`quizEventDeletions/${id}`).get()).get("status"), "deleted");
});

test("Auth deletion racing event deletion keeps its account-deleted marker", async () => {
  const id = await draft("delete-account-race");
  const uid = `${id}-member`;
  await prod.doc(`quizEvents/${id}/participants/${uid}`).set({ displayName: "Member" });
  const lock = prod.doc(`quizParticipation/${uid}`);
  await lock.set({ eventId: id, registeredAt: Timestamp.now() });
  await Promise.all([call("prod", "deleteEvent", { eventId: id }), deleteAuthUserData(uid, prod)]);
  assert.deepEqual((await lock.get()).data(), { accountDeleted: true });
  assert.deepEqual(await prod.doc(`quizEvents/${id}`).listCollections(), []);
});

test("deletion racing registration, check-in, team selection, answers or question progress leaves no event data", async () => {
  for (const operation of ["register", "checkIn", "selectTeam", "answer", "presentQuestion", "openQuestion"]) {
    const id = await draft(`delete-${operation}-race`);
    const ref = prod.doc(`quizEvents/${id}`);
    const person = participant(`${id}-member`);
    const now = Timestamp.now();
    const status = operation === "answer" ? "inProgress" : ["presentQuestion", "openQuestion"].includes(operation) ? "entryClosed" : "registration";
    await ref.update({ status, isPublic: false, admissionSlotsReady: true, teamSelectionStatus: operation === "checkIn" || operation === "selectTeam" ? "open" : "closed",
      currentQuestionId: operation === "answer" ? "q1" : null });
    if (operation !== "register") {
      await ref.collection("participants").doc(person.uid).set({ displayName: "Member", registeredAt: now,
        ...(operation === "checkIn" ? {} : { checkedInAt: now }),
        ...(operation === "selectTeam" ? {} : { teamId: "A" }) });
      await prod.doc(`quizParticipation/${person.uid}`).set({ eventId: id, registeredAt: now });
    }
    await ref.collection("secret").doc("checkIn").set({ code: "123456" });
    if (operation === "answer") {
      await ref.collection("questions").doc("q1").update({ status: "open", openedAt: now, closesAt: Timestamp.fromMillis(now.toMillis() + 180000) });
      await ref.collection("teams").doc("A").set({ memberUids: [person.uid] });
      await ref.collection("answers").doc("q1_A").set({ questionId: "q1", teamId: "A", selectedOptionIndex: null });
    }
    const write = () => {
      if (operation === "register") return registerQuizParticipantForUser(person, { eventId: id }, participantDeps);
      if (operation === "checkIn") return checkInQuizParticipantForUser(person, { eventId: id, code: "123456" }, participantDeps);
      if (operation === "selectTeam") return selectQuizTeamForUser(person, { eventId: id, teamId: "A", expectedTeamId: null }, prod);
      if (operation === "answer") return submitQuizAnswerForUser(person, { eventId: id, questionId: "q1", teamId: "A", selectedOptionIndex: 0 }, prod);
      return call("prod", "quizOperation", { eventId: id, operation, questionId: "q1", operationId: randomUUID() });
    };
    const [deletion] = await Promise.allSettled([call("prod", "deleteEvent", { eventId: id }), write()]);
    assert.equal(deletion.status, "fulfilled", operation);
    assert.equal((await ref.get()).exists, false, operation);
    assert.deepEqual(await ref.listCollections(), [], operation);
    assert.equal((await prod.doc(`quizParticipation/${person.uid}`).get()).exists, false, operation);
    await assert.rejects(write(), { code: operation === "answer" ? "permission-denied" : "failed-precondition" });
  }
});
