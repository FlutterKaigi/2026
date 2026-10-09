const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { before, after, test } = require("node:test");
const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { registerQuizParticipantForUser } = require("../lib/quiz_service.js");

function localHost(name, fallback) {
  const value = process.env[name] ?? fallback;
  assert.match(
    value,
    /^(localhost|127\.0\.0\.1|\[::1\]):\d+$/,
    `${name} must be local`,
  );
  process.env[name] = value;
  return value;
}
const authHost = localHost("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099");
const firestoreHost = localHost("FIRESTORE_EMULATOR_HOST", "127.0.0.1:8080");
const functionsHost = localHost("FUNCTIONS_EMULATOR_HOST", "127.0.0.1:5001");
const projectId =
  process.env.QUIZ_TEST_PROJECT_ID ??
  process.env.SUPPORT_LT_TEST_PROJECT_ID ??
  "demo-quiz-production";
const app = initializeApp({ projectId }, `quiz-${randomUUID()}`);
const db = getFirestore(app);
const auth = getAuth(app);
const prefix = `quiz-${randomUUID().slice(0, 8)}`;
const users = [];
const events = [];
let admin, attendee, teammate, stranger;
const documentsUrl = `http://${firestoreHost}/v1/projects/${projectId}/databases/(default)/documents`;

async function newUser(label, domain = "example.test") {
  const password = randomUUID();
  const user = await auth.createUser({
    uid: `${prefix}-${label}`,
    email: `${prefix}-${label}@${domain}`,
    password,
    emailVerified: true,
    displayName: `Account ${label}`,
  });
  users.push(user.uid);
  const response = await fetch(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-key`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: user.email,
        password,
        returnSecureToken: true,
      }),
    },
  );
  assert.equal(response.status, 200);
  return { uid: user.uid, token: (await response.json()).idToken };
}
async function call(name, user, data) {
  if (name === "quizEventOperation")
    data = { operationId: randomUUID(), ...data };
  const response = await fetch(
    `http://${functionsHost}/${projectId}/asia-northeast1/${name}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(user ? { Authorization: `Bearer ${user.token}` } : {}),
      },
      body: JSON.stringify({ data }),
    },
  );
  return response.json();
}
async function success(name, user, data) {
  if (name === "quizEventOperation")
    data = { operationId: randomUUID(), ...data };
  let result;
  for (let retry = 0; retry < 3; retry++) {
    result = await call(name, user, data);
    if (
      name !== "quizEventOperation" ||
      !["ABORTED", "UNAVAILABLE", "DEADLINE_EXCEEDED"].includes(
        result.error?.status,
      )
    )
      break;
    console.log(
      `Retrying ${data.operation} after ${result.error.status} with the same operationId`,
    );
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  assert.equal(result.error, undefined, JSON.stringify(result));
  return result.result;
}
async function error(name, user, data, code) {
  const result = await call(name, user, data);
  assert.equal(result.error?.status, code, JSON.stringify(result));
}
function op(eventId, operation, values = {}) {
  return success("quizEventOperation", admin, {
    eventId,
    operation,
    ...values,
  });
}
function register(eventId, user, entryCode = "123456") {
  return success("registerQuizParticipant", user, {
    eventId,
    displayName: "受付の名前",
    entryCode,
  });
}
async function seedEvent(label, status = "registration", members = []) {
  const eventId = `${prefix}-${label}`;
  events.push(eventId);
  const ref = db.doc(`quizEvents/${eventId}`);
  const batch = db.batch();
  batch.set(ref, {
    title: { ja: label, en: label },
    status,
    isPublic: status !== "draft",
    capacity: 80,
    sponsorIds: ["sponsor"],
    teamNamePool: [],
    currentQuestionId: null,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });
  for (const uid of members)
    batch.set(ref.collection("participants").doc(uid), {
      displayName: uid,
      registeredAt: Timestamp.now(),
    });
  await batch.commit();
  if (status === "registration") await op(eventId, "openRegistration");
  return eventId;
}
async function prepareTeams(eventId) {
  await op(eventId, "openTeamSelection");
  const participants = await db.collection(`quizEvents/${eventId}/participants`).get();
  const batch = db.batch();
  for (const participant of participants.docs) batch.update(participant.ref, { teamId: "A" });
  await batch.commit();
  await op(eventId, "closeTeamSelection");
}
function select(eventId, user, teamId, expectedTeamId = null) {
  return success("selectQuizTeam", user, { eventId, teamId, expectedTeamId });
}
async function seedQuestion(eventId, questionId = "q1", status = "draft") {
  const ref = db.doc(`quizEvents/${eventId}/questions/${questionId}`);
  await ref.set({
    sponsorId: "sponsor",
    order: questionId === "q1" ? 1 : 2,
    title: { ja: "問題", en: "Question" },
    options: [
      { ja: "はい", en: "Yes" },
      { ja: "いいえ", en: "No" },
    ],
    durationSeconds: 180,
    status,
    openedAt: null,
    closesAt: null,
    correctOptionIndex: null,
    explanation: null,
  });
  await ref
    .collection("secret")
    .doc("answer")
    .set({
      correctOptionIndex: 0,
      explanation: { ja: "解説", en: "Explanation" },
    });
}
async function clientPatch(path, user, fields) {
  const query = Object.keys(fields)
    .map((key) => `updateMask.fieldPaths=${key}`)
    .join("&");
  return fetch(`${documentsUrl}/${path}?${query}`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${user.token}`,
    },
    body: JSON.stringify({ fields }),
  });
}
before(async () => {
  [admin, attendee, teammate, stranger] = await Promise.all([
    newUser("admin", "flutterkaigi.jp"),
    newUser("attendee"),
    newUser("teammate"),
    newUser("stranger"),
  ]);
  await db.doc(`admins/${admin.uid}`).set({});
});
after(async () => {
  for (const eventId of events)
    await db.recursiveDelete(db.doc(`quizEvents/${eventId}`));
  const cleanup = db.batch();
  for (const uid of users) {
    cleanup.delete(db.doc(`admins/${uid}`));
    cleanup.delete(db.doc(`quizParticipation/${uid}`));
  }
  await cleanup.commit();
  // Use one Auth cleanup request for the load-test accounts.
  // Auth deletion behavior is exercised separately by the integration suite.
  await auth.deleteUsers(users);
  await deleteApp(app);
});

test("callables enforce auth and admin privileges", async () => {
  const eventId = await seedEvent("auth");
  await error(
    "registerQuizParticipant",
    undefined,
    { eventId, displayName: "A", entryCode: "123456" },
    "UNAUTHENTICATED",
  );
  await error(
    "quizEventOperation",
    attendee,
    { eventId, operation: "closeRegistration" },
    "PERMISSION_DENIED",
  );
  await error(
    "selectQuizTeam",
    stranger,
    { eventId, teamId: "A", expectedTeamId: null },
    "FAILED_PRECONDITION",
  );
  const clock = await success("getQuizServerTime", attendee, {});
  assert.ok(Math.abs(clock.serverNowMs - Date.now()) < 5000);
});

test("79 participants plus two simultaneous registrations admits exactly one, and retry remains idempotent", async () => {
  const eventId = await seedEvent(
    "capacity",
    "registration",
    Array.from({ length: 79 }, (_, i) => `${prefix}-capacity-${i}`),
  );
  const attempts = await Promise.all(
    [attendee, teammate].map((user) =>
      call("registerQuizParticipant", user, {
        eventId,
        displayName: "A",
        entryCode: "123456",
      }),
    ),
  );
  assert.equal(
    attempts.filter((result) => result.result?.registered).length,
    1,
  );
  assert.equal(
    attempts.filter((result) => result.error?.status === "RESOURCE_EXHAUSTED")
      .length,
    1,
  );
  assert.equal(
    (await db.collection(`quizEvents/${eventId}/participants`).get()).size,
    80,
  );
  const winner = [attendee, teammate][
    attempts.findIndex((result) => result.result?.registered)
  ];
  await op(eventId, "closeRegistration");
  await register(eventId, winner, "654321");
  const account = (
    await db
      .doc(`quizEvents/${eventId}/participantAccounts/${winner.uid}`)
      .get()
  ).data();
  assert.equal(
    account.accountName,
    winner === attendee ? "Account attendee" : "Account teammate",
  );
  // Independent later test events should not inherit this registration.
  await op(eventId, "removeParticipant", { uid: winner.uid });
});

test("global lock rejects concurrent registration for both rounds and detects legacy enrollment", async () => {
  const first = await seedEvent("round1");
  const second = await seedEvent("round2");
  const attempts = await Promise.all(
    [first, second].map((eventId) =>
      call("registerQuizParticipant", attendee, {
        eventId,
        displayName: "A",
        entryCode: "123456",
      }),
    ),
  );
  assert.equal(
    attempts.filter((result) => result.result?.registered).length,
    1,
  );
  assert.equal(
    attempts.filter((result) => result.error?.status === "ALREADY_EXISTS")
      .length,
    1,
  );
  const won = [first, second][
    attempts.findIndex((result) => result.result?.registered)
  ];
  await op(won, "removeParticipant", { uid: attendee.uid });
  const legacy = await seedEvent("legacy", "finished", [attendee.uid]);
  await error(
    "registerQuizParticipant",
    attendee,
    { eventId: first, displayName: "A", entryCode: "123456" },
    "ALREADY_EXISTS",
  );
  await db.doc(`quizEvents/${legacy}/participants/${attendee.uid}`).delete();
});

test("registration needs no code, normalizes public names and ignores old codes", async () => {
  const eventId = await seedEvent("code-free");
  const person = await newUser("code-free");
  await success("registerQuizParticipant", person, { eventId });
  const participant = db.doc(`quizEvents/${eventId}/participants/${person.uid}`);
  assert.equal((await participant.get()).get("displayName"), "参加者");
  await op(eventId, "removeParticipant", { uid: person.uid });
  await db.doc(`users/${person.uid}`).set({ displayName: "  " + "あ".repeat(30) + "  " });
  await success("registerQuizParticipant", person, { eventId });
  assert.equal((await participant.get()).get("displayName"), "あ".repeat(20));
  await op(eventId, "removeParticipant", { uid: person.uid });
  await db.doc(`users/${person.uid}`).delete();
  await success("registerQuizParticipant", person, { eventId, entryCode: "wrong", displayName: "  Legacy  " });
  assert.equal((await participant.get()).get("displayName"), "Legacy");
});

test("selection is authenticated, compares membership, survives reopening, and freezes at first question", async () => {
  const eventId = await seedEvent("selection");
  const person = await newUser("selector");
  await register(eventId, person);
  await error("selectQuizTeam", undefined, { eventId, teamId: "A", expectedTeamId: null }, "UNAUTHENTICATED");
  await error("selectQuizTeam", person, { eventId, teamId: "A", expectedTeamId: null }, "FAILED_PRECONDITION");
  await op(eventId, "openTeamSelection");
  await error("selectQuizTeam", person, { eventId, teamId: "U", expectedTeamId: null }, "INVALID_ARGUMENT");
  await select(eventId, person, "A");
  await select(eventId, person, "A");
  await select(eventId, person, "T", "A");
  await error("selectQuizTeam", person, { eventId, teamId: "B", expectedTeamId: "A" }, "FAILED_PRECONDITION");
  await op(eventId, "closeRegistration");
  await op(eventId, "closeTeamSelection");
  await select(eventId, person, "T");
  await error("selectQuizTeam", person, { eventId, teamId: "B", expectedTeamId: "T" }, "FAILED_PRECONDITION");
  await op(eventId, "reopenRegistration");
  assert.equal((await db.doc(`quizEvents/${eventId}/participants/${person.uid}`).get()).get("teamId"), "T");
  await op(eventId, "closeRegistration");
  await seedQuestion(eventId);
  await op(eventId, "openQuestion", { questionId: "q1" });
  const teams = await db.collection(`quizEvents/${eventId}/teams`).get();
  assert.deepEqual(teams.docs.map((team) => team.id), ["T"]);
  assert.equal(teams.docs[0].get("tableNumber"), 20);
  assert.equal((await db.collection(`quizEvents/${eventId}/answers`).get()).size, 1);
  await select(eventId, person, "T");
  for (const operation of ["openTeamSelection", "closeTeamSelection", "reopenRegistration", "removeUnselectedParticipants", "removeParticipant"]) {
    await error("quizEventOperation", admin, { eventId, operation, uid: person.uid }, "FAILED_PRECONDITION");
  }
});

test("initial selection removes legacy assignments; no-shows block starting and cancellation restores capacity", async () => {
  const person = await newUser("checkin");
  const missing = await newUser("missing");
  const nullTeam = await newUser("null-team");
  const deleted = await newUser("deleted-roster");
  const eventId = await seedEvent("checkin");
  for (const user of [person, missing, nullTeam, deleted]) await register(eventId, user);
  const ref = db.doc(`quizEvents/${eventId}`);
  await ref.collection("teams").doc("old").set({ name: "Old", memberUids: [person.uid] });
  await ref.collection("participants").doc(person.uid).update({ teamId: "old" });
  await error("quizEventOperation", admin, { eventId, operation: "removeUnselectedParticipants" }, "FAILED_PRECONDITION");
  await op(eventId, "closeRegistration");
  await error("quizEventOperation", admin, { eventId, operation: "removeUnselectedParticipants" }, "FAILED_PRECONDITION");
  await op(eventId, "openTeamSelection");
  assert.equal((await ref.collection("teams").get()).empty, true);
  assert.equal((await ref.collection("participants").doc(person.uid).get()).get("teamId"), undefined);
  await ref.collection("participants").doc(nullTeam.uid).update({ teamId: null });
  await db.doc(`quizParticipation/${deleted.uid}`).update({ accountDeleted: true });
  await select(eventId, person, "A");
  await seedQuestion(eventId);
  await error("quizEventOperation", admin, { eventId, operation: "presentQuestion", questionId: "q1" }, "FAILED_PRECONDITION");
  await op(eventId, "closeTeamSelection");
  await error("quizEventOperation", admin, { eventId, operation: "presentQuestion", questionId: "q1" }, "FAILED_PRECONDITION");
  assert.deepEqual(await op(eventId, "removeUnselectedParticipants"), { removedCount: 3 });
  assert.equal((await ref.collection("admissionSlots").get()).size, 1);
  assert.equal((await ref.collection("participantAccounts").get()).size, 1);
  assert.equal((await db.doc(`quizParticipation/${missing.uid}`).get()).exists, false);
  assert.equal((await db.doc(`quizParticipation/${deleted.uid}`).get()).get("accountDeleted"), true);
  const otherRound = await seedEvent("walk-in-other");
  await register(otherRound, missing);
  await op(eventId, "reopenRegistration");
  await register(eventId, nullTeam);
  await error("quizEventOperation", admin, { eventId, operation: "removeUnselectedParticipants" }, "FAILED_PRECONDITION");
  await op(eventId, "openTeamSelection");
  await select(eventId, nullTeam, "A");
  assert.equal((await ref.collection("participants").doc(person.uid).get()).get("teamId"), "A");
  await op(eventId, "closeRegistration");
  await op(eventId, "removeParticipant", { uid: nullTeam.uid });
  await op(eventId, "closeTeamSelection");
  await ref.collection("teams").doc("stray").set({ name: "Stray" });
  await error("quizEventOperation", admin, { eventId, operation: "presentQuestion", questionId: "q1" }, "FAILED_PRECONDITION");
  await ref.collection("teams").doc("stray").delete();
  await op(eventId, "presentQuestion", { questionId: "q1" });
  assert.deepEqual((await ref.collection("teams").get()).docs.map((doc) => doc.id), ["A"]);
});

test("concurrent selections and no-show cancellation leave one consistent roster", async () => {
  const eventId = await seedEvent("select-race");
  const people = await Promise.all([newUser("race-a"), newUser("race-b")]);
  for (const person of people) await register(eventId, person);
  await op(eventId, "openTeamSelection");
  const first = await Promise.all(["A", "B"].map((teamId) => call("selectQuizTeam", people[0], { eventId, teamId, expectedTeamId: null })));
  assert.equal(first.filter((result) => !result.error).length, 1);
  await op(eventId, "closeRegistration");
  const [selection] = await Promise.all([
    call("selectQuizTeam", people[1], { eventId, teamId: "T", expectedTeamId: null }),
    op(eventId, "removeUnselectedParticipants"),
  ]);
  const participant = await db.doc(`quizEvents/${eventId}/participants/${people[1].uid}`).get();
  assert.equal(participant.exists, !selection.error);
  if (participant.exists) assert.equal(participant.get("teamId"), "T");
  const roster = await db.collection(`quizEvents/${eventId}/participants`).get();
  const slots = await db.collection(`quizEvents/${eventId}/admissionSlots`).get();
  assert.equal(roster.size, slots.size);
});

test("reading has no timer, team answers overwrite, opening retries preserve answers, deadlines use server clock", async () => {
  const eventId = await seedEvent("playing", "entryClosed", [
    attendee.uid,
    teammate.uid,
    `${prefix}-third`,
  ]);
  await seedQuestion(eventId);
  await seedQuestion(eventId, "q2");
  await prepareTeams(eventId);
  const teamId = "A";
  await op(eventId, "presentQuestion", { questionId: "q1" });
  const reading = (
    await db.doc(`quizEvents/${eventId}/questions/q1`).get()
  ).data();
  assert.equal(reading.status, "reading");
  assert.equal(reading.closesAt, null);
  const payload = { eventId, questionId: "q1", teamId, selectedOptionIndex: 0 };
  await error("submitQuizAnswer", attendee, payload, "FAILED_PRECONDITION");
  await error(
    "quizEventOperation",
    admin,
    { eventId, operation: "openQuestion", questionId: "q2" },
    "FAILED_PRECONDITION",
  );
  await op(eventId, "openQuestion", { questionId: "q1" });
  const opened = (
    await db.doc(`quizEvents/${eventId}/questions/q1`).get()
  ).data();
  assert.equal(opened.closesAt.toMillis() - opened.openedAt.toMillis(), 180000);
  assert.ok(Math.abs(opened.openedAt.toMillis() - Date.now()) < 5000);
  await error("submitQuizAnswer", stranger, payload, "PERMISSION_DENIED");
  await success("submitQuizAnswer", attendee, payload);
  await success("submitQuizAnswer", teammate, {
    ...payload,
    selectedOptionIndex: 1,
  });
  await op(eventId, "openQuestion", { questionId: "q1" });
  const answerRef = db.doc(`quizEvents/${eventId}/answers/q1_${teamId}`);
  assert.equal((await answerRef.get()).get("selectedOptionIndex"), 1);
  assert.equal((await answerRef.get()).get("answeredBy"), teammate.uid);
  await db
    .doc(`quizEvents/${eventId}/questions/q1`)
    .update({ closesAt: Timestamp.fromMillis(Date.now() - 1000) });
  await error("submitQuizAnswer", attendee, payload, "FAILED_PRECONDITION");
  const extensions = await Promise.all([
    op(eventId, "extendQuestion", {
      questionId: "q1",
      seconds: 30,
      operationId: "extend1",
    }),
    op(eventId, "extendQuestion", {
      questionId: "q1",
      seconds: 30,
      operationId: "extend1",
    }),
  ]);
  assert.deepEqual(extensions[0], extensions[1]);
  await success("submitQuizAnswer", attendee, payload);
  await op(eventId, "closeQuestion", { questionId: "q1" });
  await error("submitQuizAnswer", attendee, payload, "FAILED_PRECONDITION");
  await Promise.all([
    op(eventId, "revealQuestion", { questionId: "q1" }),
    op(eventId, "revealQuestion", { questionId: "q1" }),
  ]);
  assert.equal(
    (await db.doc(`quizEvents/${eventId}/teams/${teamId}`).get()).get("score"),
    10,
  );
  await op(eventId, "openQuestion", { questionId: "q2" });
  await success("submitQuizAnswer", attendee, { ...payload, questionId: "q2" });
  await op(eventId, "closeQuestion", { questionId: "q2" });
  await Promise.all([
    op(eventId, "revealQuestion", { questionId: "q1" }),
    op(eventId, "revealQuestion", { questionId: "q2" }),
  ]);
  assert.equal(
    (await db.doc(`quizEvents/${eventId}/teams/${teamId}`).get()).get("score"),
    20,
  );
  await db.doc(`quizEvents/${eventId}/teams/${teamId}`).update({ score: 999 });
  await op(eventId, "finalizeEvent");
  const final = (
    await db.doc(`quizEvents/${eventId}/teams/${teamId}`).get()
  ).data();
  assert.equal(final.score, 20);
  assert.equal(final.rank, 1);
  assert.deepEqual(final.perfectSponsorIds, ["sponsor"]);
  await error(
    "quizEventOperation",
    admin,
    { eventId, operation: "openTeamSelection", operationId: "after" },
    "FAILED_PRECONDITION",
  );
});

test("security rules deny participant registration bypass and stale admin runtime writes", async () => {
  const eventId = await seedEvent("rules", "entryClosed", [
    stranger.uid,
    `${prefix}-r2`,
    `${prefix}-r3`,
  ]);
  await seedQuestion(eventId);
  await prepareTeams(eventId);
  const teamId = "A";
  for (const [path, user, fields] of [
    [
      `quizEvents/${eventId}/participants/${attendee.uid}`,
      attendee,
      { displayName: { stringValue: "Bypass" } },
    ],
    [
      `quizEvents/${eventId}/entryClaims/${attendee.uid}`,
      attendee,
      { code: { stringValue: "123456" } },
    ],
    [
      `quizEvents/${eventId}/participantAccounts/${attendee.uid}`,
      attendee,
      { uid: { stringValue: attendee.uid } },
    ],
    [
      `quizEvents/${eventId}`,
      admin,
      {
        status: { stringValue: "draft" },
        currentQuestionId: { nullValue: null },
      },
    ],
    [
      `quizEvents/${eventId}/teams/${teamId}`,
      admin,
      { score: { integerValue: "999" } },
    ],
    [`quizEvents/${eventId}`, admin, { teamSelectionStatus: { stringValue: "open" } }],
    [`quizEvents/${eventId}/teams/${teamId}`, admin, { name: { stringValue: "Changed" } }],
    [
      `quizEvents/${eventId}/secret/entry`,
      admin,
      { code: { stringValue: "654321" } },
    ],
  ])
    assert.equal((await clientPatch(path, user, fields)).status, 403, path);
  await op(eventId, "openQuestion", { questionId: "q1" });
  for (const [path, user, fields] of [
    [
      `quizEvents/${eventId}/questions/q1`,
      admin,
      { status: { stringValue: "draft" } },
    ],
    [
      `quizEvents/${eventId}/questions/q1/secret/answer`,
      admin,
      { correctOptionIndex: { integerValue: "1" } },
    ],
    [
      `quizEvents/${eventId}/answers/q1_${teamId}`,
      stranger,
      { selectedOptionIndex: { integerValue: "1" } },
    ],
  ])
    assert.equal((await clientPatch(path, user, fields)).status, 403, path);
});

test("security rules still allow dashboard draft creation and content-only configuration updates", async () => {
  const eventId = `${prefix}-editor`;
  events.push(eventId);
  const eventPath = `quizEvents/${eventId}`;
  const documentName = (path) =>
    `projects/${projectId}/databases/(default)/documents/${path}`;
  const locale = (text) => ({
    mapValue: {
      fields: { ja: { stringValue: text }, en: { stringValue: text } },
    },
  });
  async function commit(writes) {
    const result = await fetch(`${documentsUrl}:commit`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${admin.token}`,
      },
      body: JSON.stringify({ writes }),
    });
    const body = await result.json();
    assert.equal(result.status, 200, JSON.stringify(body));
  }
  const eventFields = {
    title: locale("Event"),
    status: { stringValue: "draft" },
    isPublic: { booleanValue: false },
    currentQuestionId: { nullValue: null },
    capacity: { integerValue: "80" },
    sponsorIds: { arrayValue: { values: [] } },
    teamNamePool: { arrayValue: { values: [] } },
  };
  await commit([
    {
      update: { name: documentName(eventPath), fields: eventFields },
      updateTransforms: [
        { fieldPath: "createdAt", setToServerValue: "REQUEST_TIME" },
        { fieldPath: "updatedAt", setToServerValue: "REQUEST_TIME" },
      ],
    },
  ]);
  const questionFields = {
    sponsorId: { stringValue: "sponsor" },
    order: { integerValue: "1" },
    title: locale("Question"),
    options: { arrayValue: { values: [locale("Yes"), locale("No")] } },
    durationSeconds: { integerValue: "180" },
    status: { stringValue: "draft" },
    openedAt: { nullValue: null },
    closesAt: { nullValue: null },
    correctOptionIndex: { nullValue: null },
    explanation: { nullValue: null },
  };
  await commit([
    {
      update: {
        name: documentName(`${eventPath}/questions/q1`),
        fields: questionFields,
      },
    },
    {
      update: {
        name: documentName(`${eventPath}/questions/q1/secret/answer`),
        fields: {
          correctOptionIndex: { integerValue: "0" },
          explanation: locale("Because"),
        },
      },
    },
  ]);
  assert.equal(
    (
      await clientPatch(`${eventPath}/questions/q1`, admin, {
        durationSeconds: { integerValue: "200" },
      })
    ).status,
    200,
  );
  await db
    .doc(eventPath)
    .update({ status: "inProgress", isPublic: true, currentQuestionId: "q1" });
  assert.equal((await clientPatch(eventPath, admin, { teamNamePool: { arrayValue: { values: [{ stringValue: "Changed" }] } } })).status, 403);
  assert.equal((await db.doc(eventPath).get()).get("currentQuestionId"), "q1");
  assert.equal((await db.doc(eventPath).get()).get("status"), "inProgress");
});

test("receipts prevent delayed close and selection retries undoing later operations", async () => {
  const eventId = await seedEvent("receipts", "registration", [
    attendee.uid,
    teammate.uid,
    `${prefix}-receipt3`,
  ]);
  await op(eventId, "closeRegistration", { operationId: "close-reception" });
  await op(eventId, "reopenRegistration");
  await op(eventId, "closeRegistration", { operationId: "close-reception" });
  assert.equal(
    (await db.doc(`quizEvents/${eventId}`).get()).get("status"),
    "registration",
  );
  await op(eventId, "openTeamSelection", { operationId: "select-open" });
  await op(eventId, "closeTeamSelection");
  await op(eventId, "openTeamSelection", { operationId: "select-open" });
  assert.equal((await db.doc(`quizEvents/${eventId}`).get()).get("teamSelectionStatus"), "closed");
  await error("quizEventOperation", admin, { eventId, operation: "closeTeamSelection", operationId: "select-open" }, "FAILED_PRECONDITION");
  await op(eventId, "closeRegistration");
  await seedQuestion(eventId);
  await prepareTeams(eventId);
  await op(eventId, "openQuestion", { questionId: "q1" });
  await op(eventId, "closeQuestion", {
    questionId: "q1",
    operationId: "close-q1",
  });
  const extension = await op(eventId, "extendQuestion", {
    questionId: "q1",
    seconds: 30,
    operationId: "extend-q1",
  });
  await op(eventId, "closeQuestion", {
    questionId: "q1",
    operationId: "close-q1",
  });
  const current = (
    await db.doc(`quizEvents/${eventId}/questions/q1`).get()
  ).data();
  assert.equal(current.status, "open");
  assert.equal(current.closesAt.toMillis(), extension.closesAtMs);
  await error(
    "quizEventOperation",
    admin,
    {
      eventId,
      operation: "extendQuestion",
      questionId: "q1",
      seconds: 60,
      operationId: "extend-q1",
    },
    "FAILED_PRECONDITION",
  );
  await error(
    "quizEventOperation",
    admin,
    {
      eventId,
      operation: "closeQuestion",
      questionId: "q2",
      operationId: "close-q1",
    },
    "FAILED_PRECONDITION",
  );
});

test("early finalization counts only revealed questions and never awards an unasked sponsor", async () => {
  const eventId = await seedEvent("early-finish", "entryClosed", [
    stranger.uid,
    `${prefix}-early2`,
    `${prefix}-early3`,
  ]);
  await seedQuestion(eventId);
  await seedQuestion(eventId, "q2");
  await seedQuestion(eventId, "q3");
  await db
    .doc(`quizEvents/${eventId}/questions/q3`)
    .update({ sponsorId: "unasked-sponsor" });
  await prepareTeams(eventId);
  const teamId = "A";
  await op(eventId, "presentQuestion", { questionId: "q1" });
  await error(
    "quizEventOperation",
    admin,
    { eventId, operation: "finalizeEvent" },
    "FAILED_PRECONDITION",
  );
  await op(eventId, "openQuestion", { questionId: "q1" });
  await success("submitQuizAnswer", stranger, {
    eventId,
    questionId: "q1",
    teamId,
    selectedOptionIndex: 0,
  });
  await error(
    "quizEventOperation",
    admin,
    { eventId, operation: "finalizeEvent" },
    "FAILED_PRECONDITION",
  );
  await op(eventId, "closeQuestion", { questionId: "q1" });
  await error(
    "quizEventOperation",
    admin,
    { eventId, operation: "finalizeEvent" },
    "FAILED_PRECONDITION",
  );
  await op(eventId, "revealQuestion", { questionId: "q1" });
  await op(eventId, "finalizeEvent");
  const team = (
    await db.doc(`quizEvents/${eventId}/teams/${teamId}`).get()
  ).data();
  assert.equal(team.score, 10);
  assert.deepEqual(team.perfectSponsorIds, ["sponsor"]);
  assert.equal(
    (await db.doc(`quizEvents/${eventId}/questions/q2`).get()).get("status"),
    "draft",
  );
  assert.equal(
    (await db.doc(`quizEvents/${eventId}`).get()).get("status"),
    "finished",
  );
});

test("finalization racing the next presentation commits exactly one transition", async () => {
  const eventId = await seedEvent("finish-race", "entryClosed", [
    `${prefix}-race1`,
    `${prefix}-race2`,
    `${prefix}-race3`,
  ]);
  await seedQuestion(eventId);
  await seedQuestion(eventId, "q2");
  await prepareTeams(eventId);
  await op(eventId, "openQuestion", { questionId: "q1" });
  await op(eventId, "closeQuestion", { questionId: "q1" });
  await op(eventId, "revealQuestion", { questionId: "q1" });
  const results = await Promise.all([
    call("quizEventOperation", admin, { eventId, operation: "finalizeEvent" }),
    call("quizEventOperation", admin, {
      eventId,
      operation: "presentQuestion",
      questionId: "q2",
    }),
  ]);
  assert.equal(
    results.filter((result) => !result.error).length,
    1,
    JSON.stringify(results),
  );
  assert.equal(
    results.filter((result) => result.error?.status === "FAILED_PRECONDITION")
      .length,
    1,
    JSON.stringify(results),
  );
  const event = (await db.doc(`quizEvents/${eventId}`).get()).data();
  const question = (
    await db.doc(`quizEvents/${eventId}/questions/q2`).get()
  ).data();
  assert.ok(
    (event.status === "finished" && question.status === "draft") ||
      (event.status === "inProgress" && question.status === "reading"),
  );
});

test(
  "80 distinct accounts registering simultaneously through the service never exceed capacity",
  { timeout: 180000 },
  async () => {
    const eventId = await seedEvent("full-load");
    const accounts = await Promise.all(
      Array.from({ length: 80 }, (_, index) => newUser(`load-${index}`)),
    );
    assert.equal(
      (await db.doc(`quizEvents/${eventId}`).get()).get("admissionSlotsReady"),
      true,
    );
    const identities = await Promise.all(
      accounts.map(async (user) => ({
        uid: user.uid,
        token: await auth.verifyIdToken(user.token),
      })),
    );
    async function attempt(identity) {
      try {
        return {
          result: await registerQuizParticipantForUser(
            identity,
            { eventId, displayName: "Load", entryCode: "123456" },
            { db, getUser: (uid) => auth.getUser(uid) },
          ),
        };
      } catch (error) {
        return {
          error: {
            status: String(error.code).toUpperCase().replaceAll("-", "_"),
            message: error.message,
          },
        };
      }
    }
    // Firebase CLI forks a Node process for each concurrent HTTP request,
    // unlike a v2 production instance's concurrent requests in one process.
    // Keep callable auth/rules coverage above and load the real service + DB/Auth
    // in one process so the 80-person test measures admission transactions.
    const start = Date.now();
    const attempts = await Promise.all(identities.map(attempt));
    const counts = attempts.reduce((summary, result) => {
      const key =
        result.error?.status ??
        (result.result?.registered === true
          ? "OK"
          : `INVALID_RESULT:${JSON.stringify(result)}`);
      summary[key] = (summary[key] ?? 0) + 1;
      return summary;
    }, {});
    console.log(
      "Quiz 80 simultaneous first attempt:",
      JSON.stringify({ counts, elapsedMs: Date.now() - start }),
    );
    assert.ok(
      attempts.every(
        (result) =>
          !result.error ||
          ["ABORTED", "DEADLINE_EXCEEDED", "UNAVAILABLE"].includes(
            result.error.status,
          ),
      ),
      JSON.stringify(counts),
    );
    const initialRoster = await db
      .collection(`quizEvents/${eventId}/participants`)
      .get();
    const pointDocs = await db.getAll(
      ...accounts.map((user) =>
        db.doc(`quizEvents/${eventId}/participants/${user.uid}`),
      ),
    );
    const initialIds = new Set(
      pointDocs.filter((doc) => doc.exists).map((doc) => doc.id),
    );
    const acknowledgedIds = accounts
      .filter((_, index) => attempts[index].result?.registered === true)
      .map((user) => user.uid);
    console.log(
      "Quiz 80 initial roster:",
      JSON.stringify({
        size: initialRoster.size,
        pointCount: initialIds.size,
        slots: (
          await db.collection(`quizEvents/${eventId}/admissionSlots`).get()
        ).size,
        missingAcknowledged: acknowledgedIds.filter(
          (uid) => !initialIds.has(uid),
        ),
      }),
    );
    assert.ok(
      acknowledgedIds.every((uid) => initialIds.has(uid)),
      "Acknowledged registrations must persist",
    );
    assert.ok(initialRoster.size <= 80);
    for (const [index, result] of attempts.entries()) {
      if (result.error)
        assert.equal((await attempt(identities[index])).error, undefined);
    }
    const final = await db
      .collection(`quizEvents/${eventId}/participants`)
      .get();
    console.log("Quiz 80 simultaneous final count:", final.size);
    assert.equal(final.size, 80);
    assert.equal(
      (await db.collection(`quizEvents/${eventId}/admissionSlots`).get()).size,
      80,
    );
  },
);

test("participants cannot freeze an unopened event and admins cannot shrink reserved capacity", async () => {
  const eventId = await seedEvent("reservation-rules", "published");
  await error(
    "registerQuizParticipant",
    stranger,
    { eventId, displayName: "Name", entryCode: "123456" },
    "FAILED_PRECONDITION",
  );
  assert.equal(
    (await db.doc(`quizEvents/${eventId}`).get()).get("admissionSlotsReady"),
    undefined,
  );
  await op(eventId, "openRegistration");
  const result = await fetch(`${documentsUrl}:commit`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${admin.token}`,
    },
    body: JSON.stringify({
      writes: [
        {
          update: {
            name: `projects/${projectId}/databases/(default)/documents/quizEvents/${eventId}`,
            fields: { capacity: { integerValue: "3" } },
          },
          updateMask: { fieldPaths: ["capacity"] },
          updateTransforms: [
            { fieldPath: "updatedAt", setToServerValue: "REQUEST_TIME" },
          ],
        },
      ],
    }),
  });
  assert.equal(result.status, 403);
  assert.equal(
    (
      await clientPatch(`quizEvents/${eventId}/admissionSlots/0`, stranger, {
        uid: { stringValue: stranger.uid },
      })
    ).status,
    403,
  );
});
