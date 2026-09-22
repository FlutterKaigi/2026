const assert = require("node:assert/strict");
const { test } = require("node:test");
const { Timestamp } = require("firebase-admin/firestore");
const { administerEvent, eventTargetProject, eventJson } = require("../lib/event_admin_service.js");

const admin = { uid: "source-admin", token: { email: "admin@flutterkaigi.jp", email_verified: true } };
const adminDb = {
  collection: (name) => ({ doc: (uid) => ({ get: async () => {
    assert.equal(name, "admins");
    assert.equal(uid, "source-admin");
    return { exists: true };
  } }) }),
};

test("only named live projects and emulator-local requests can be selected", () => {
  for (const source of ["flutterkaigi-2026-stg", "flutterkaigi-2026-283db"]) {
    assert.equal(eventTargetProject("prod", source, false), "flutterkaigi-2026-283db");
    assert.equal(eventTargetProject("stg", source, false), "flutterkaigi-2026-stg");
    for (const value of ["dev", "other", "flutterkaigi-2026-283db", null, {}, "prod/other"]) {
      assert.throws(() => eventTargetProject(value, source, false), { code: "invalid-argument" });
    }
  }
  assert.equal(eventTargetProject("dev", "demo-test", true), "demo-test");
  for (const value of ["stg", "prod"]) {
    assert.throws(() => eventTargetProject(value, "demo-test", true), { code: "invalid-argument" });
    assert.throws(() => eventTargetProject(value, "untrusted-project", false), { code: "invalid-argument" });
  }
});

test("authorization in the source project happens before any target access", async () => {
  for (const [auth, db, getUser, code] of [
    [undefined, adminDb, async () => ({ disabled: false }), "unauthenticated"],
    [{ ...admin, token: { ...admin.token, email_verified: false } }, adminDb, async () => ({ disabled: false }), "permission-denied"],
    [{ ...admin, token: { ...admin.token, email: "attendee@example.test" } }, adminDb, async () => ({ disabled: false }), "permission-denied"],
    [admin, { collection: () => ({ doc: () => ({ get: async () => ({ exists: false }) }) }) }, async () => ({ disabled: false }), "permission-denied"],
    [admin, adminDb, async () => ({ disabled: true }), "permission-denied"],
    [admin, adminDb, async () => { throw { code: "auth/user-not-found" }; }, "unauthenticated"],
  ]) {
    await assert.rejects(administerEvent(auth, { environment: "prod", action: "read" }, {
      adminDb: db, getUser, target: () => assert.fail("Unauthorized target access"),
    }), { code });
  }
});

test("the existing source account reads the selected project without a target account", async () => {
  for (const environment of ["stg", "prod"]) {
    const result = await administerEvent(admin, { environment, action: "read", payload: { view: "supportLt" } }, {
      adminDb, getUser: async (uid) => { assert.equal(uid, "source-admin"); return { disabled: false }; },
      target: (selected) => {
        assert.equal(selected, environment);
        return {
          doc: (path) => ({ get: async () => {
            assert.equal(path, "supportLtSettings/current");
            return { id: "current", exists: true, data: () => ({ code: environment, issuedAt: Timestamp.fromMillis(0) }) };
          } }),
          collection: (path) => {
            assert.equal(path, "supportLtRegistrations"); // No admins or Auth in the target project.
            return { orderBy: () => ({ get: async () => ({ docs: [] }) }) };
          },
        };
      },
    });
    assert.equal(result.code.code, environment);
    assert.equal(result.code.issuedAt, "1970-01-01T00:00:00.000Z");
  }
});

test("malformed and arbitrary path writes are rejected without writing", async () => {
  const db = { doc: () => ({}), collection: () => ({}), runTransaction: () => assert.fail("Invalid write") };
  for (const [action, payload] of [
    ["saveEvent", { eventId: "../admins" }],
    ["saveEvent", { eventId: "event", title: { ja: "Quiz", en: "Quiz" }, capacity: 81 }],
    ["saveQuestion", { eventId: "event", questionId: "x/y" }],
    ["renameTeam", { eventId: "x/y", teamId: "team", name: "Name" }],
    ["renameTeam", { eventId: "event", teamId: "..", name: "Name" }],
    ["renameTeam", { eventId: "event", teamId: "team", name: "" }],
    ["writeAnyDocument", { path: "admins/member" }],
    ["read", { view: "admins" }],
  ]) {
    await assert.rejects(administerEvent(admin, { environment: "prod", action, payload }, {
      adminDb, getUser: async () => ({ disabled: false }), target: () => db,
    }), { code: "invalid-argument" });
  }
});

test("nested timestamps have a consistent callable wire format", () => {
  assert.deepEqual(eventJson({ array: [{ at: Timestamp.fromMillis(0) }], empty: null }), {
    array: [{ at: "1970-01-01T00:00:00.000Z" }], empty: null,
  });
});
