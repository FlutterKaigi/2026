const assert = require("node:assert/strict");
const { test } = require("node:test");
const {
  checkInQuizParticipantForUser,
  quizDisplayName,
  selectQuizTeamForUser,
  registerQuizParticipantForUser,
  submitQuizAnswerForUser,
} = require("../lib/quiz_service.js");

test("public names trim, truncate by grapheme, and always have a fallback", () => {
  assert.equal(quizDisplayName(undefined), "参加者");
  assert.equal(quizDisplayName("   "), "参加者");
  assert.equal(quizDisplayName("  Alice  "), "Alice");
  const emoji = "👨‍👩‍👦";
  assert.equal(quizDisplayName(emoji.repeat(30)), emoji.repeat(20));
});
test("missing and anonymous accounts cannot register or answer", async () => {
  const anonymous = {
    uid: "anonymous",
    token: { firebase: { sign_in_provider: "anonymous" } },
  };
  for (const [auth, code] of [
    [undefined, "unauthenticated"],
    [anonymous, "permission-denied"],
  ]) {
    await assert.rejects(registerQuizParticipantForUser(auth, {}, {}), {
      code,
    });
    await assert.rejects(submitQuizAnswerForUser(auth, {}, {}), { code });
    await assert.rejects(selectQuizTeamForUser(auth, {}, {}), { code });
    await assert.rejects(checkInQuizParticipantForUser(auth, {}, {}), { code });
  }
});
test("malformed event requests are rejected before database access", async () => {
  const auth = {
    uid: "member",
    token: { firebase: { sign_in_provider: "password" } },
  };
  for (const data of [
    null,
    {},
    { eventId: "bad/id" },
  ]) {
    await assert.rejects(registerQuizParticipantForUser(auth, data, {}), {
      code: "invalid-argument",
    });
  }
  for (const data of [
    { eventId: "event" },
    { eventId: "event", code: 123456 },
    { eventId: "event", code: "12345" },
    { eventId: "event", code: "１２３４５６" },
    { eventId: "bad/id", code: "123456" },
  ]) {
    await assert.rejects(checkInQuizParticipantForUser(auth, data, {}), {
      code: "invalid-argument",
    });
  }
});

test("an account deletion tombstone blocks check-in before attempts can be recreated", async () => {
  const auth = {
    uid: "deleted",
    token: { firebase: { sign_in_provider: "password" } },
  };
  const ref = { collection: () => ({ doc: () => ref }) };
  const db = {
    doc: () => ref,
    runTransaction: async (callback) =>
      callback({
        get: async () => ({
          get: (field) => (field === "accountDeleted" ? true : undefined),
        }),
        getAll: async () => assert.fail("A tombstone should reject before reading the event"),
        set: () => assert.fail("A tombstone should not record an attempt"),
      }),
  };
  await assert.rejects(
    checkInQuizParticipantForUser(
      auth,
      { eventId: "event", code: "123456" },
      {
        db,
        getUser: async () => {
          assert.fail("A tombstone should reject before Auth lookup");
        },
      },
    ),
    { code: "unauthenticated" },
  );
});

test("an account deletion tombstone blocks registration even if Auth lookup would still succeed", async () => {
  const auth = {
    uid: "deleted",
    token: { firebase: { sign_in_provider: "password" } },
  };
  const ref = {
    get: async () => ({
      get: (field) => (field === "admissionSlotsReady" ? true : 80),
    }),
    collection: () => ({ doc: () => ref, get: async () => ({ docs: [] }) }),
  };
  const db = {
    doc: () => ref,
    collection: () => ({ get: async () => ({ docs: [] }) }),
    runTransaction: async (callback) =>
      callback({
        get: async () => ({
          get: (field) => (field === "accountDeleted" ? true : undefined),
        }),
      }),
  };
  await assert.rejects(
    registerQuizParticipantForUser(
      auth,
      { eventId: "event", displayName: "Name", entryCode: "123456" },
      {
        db,
        getUser: async () => {
          assert.fail("A tombstone should reject before Auth lookup");
        },
      },
    ),
    { code: "unauthenticated" },
  );
});
