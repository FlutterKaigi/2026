const assert = require("node:assert/strict");
const { test } = require("node:test");
const {
  splitQuizTeamSizes,
  registerQuizParticipantForUser,
  submitQuizAnswerForUser,
} = require("../lib/quiz_service.js");

test("every supported roster partitions into 3-5 people with no losses and at most 20 tables", () => {
  for (let count = 3; count <= 80; count++) {
    const sizes = splitQuizTeamSizes(count);
    assert.equal(
      sizes.reduce((total, size) => total + size, 0),
      count,
    );
    assert.ok(
      sizes.every((size) => size >= 3 && size <= 5),
      `Invalid partition for ${count}`,
    );
    assert.ok(sizes.length <= 20);
  }
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
  }
});
test("malformed code and participant names are rejected before database access", async () => {
  const auth = {
    uid: "member",
    token: { firebase: { sign_in_provider: "password" } },
  };
  for (const data of [
    null,
    {},
    { eventId: "bad/id" },
    { eventId: "one", displayName: " ", entryCode: "123456" },
    { eventId: "one", displayName: "x".repeat(21), entryCode: "123456" },
    { eventId: "one", displayName: "Name", entryCode: "12345" },
  ]) {
    await assert.rejects(registerQuizParticipantForUser(auth, data, {}), {
      code: "invalid-argument",
    });
  }
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
