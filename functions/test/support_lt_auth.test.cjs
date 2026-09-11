const assert = require("node:assert/strict");
const { test } = require("node:test");
const { assertActiveSupportLtUser, InactiveSupportLtUserError } = require("../lib/support_lt_auth.js");

test("active Auth accounts pass the non-mutating check", async () => {
  await assertActiveSupportLtUser("attendee", async (uid) => {
    assert.equal(uid, "attendee");
    return { disabled: false };
  });
});

test("deleted and disabled accounts produce typed rejection for cleanup after transaction rollback", async () => {
  const missing = Object.assign(new Error("Deleted"), { code: "auth/user-not-found" });
  await assert.rejects(assertActiveSupportLtUser("attendee", async () => { throw missing; }),
    (error) => error instanceof InactiveSupportLtUserError && error.code === "unauthenticated" && error.deleted === true);
  await assert.rejects(assertActiveSupportLtUser("attendee", async () => ({ disabled: true })),
    (error) => error instanceof InactiveSupportLtUserError && error.code === "permission-denied" && error.deleted === false);
});

test("transient and unexpected Auth failures propagate instead of treating a user as deleted", async () => {
  for (const failure of [new Error("Auth unavailable"), { code: "auth/internal-error" }, null, "failure"]) {
    await assert.rejects(assertActiveSupportLtUser("attendee", async () => { throw failure; }),
      (error) => error === failure);
  }
});
