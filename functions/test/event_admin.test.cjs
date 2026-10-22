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
    for (const action of ["read", "deleteEvent"]) {
      await assert.rejects(administerEvent(auth, { environment: "prod", action, payload: { view: "quizConsole", eventId: "event" } }, {
        adminDb: db, getUser, target: () => assert.fail("Unauthorized target access"),
      }), { code });
    }
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
    ["deleteEvent", { eventId: "../admins" }],
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

test("projection reads participants only before questions begin", async () => {
  for (const status of ["draft", "published", "registration", "entryClosed", "inProgress", "finished"]) {
    const reads = [];
    const result = await administerEvent(admin, { environment: "prod", action: "read", payload: { view: "quizProjection", eventId: "event" } }, {
      adminDb, getUser: async () => ({ disabled: false }),
      target: () => ({
        doc: (path) => ({ get: async () => {
          assert.equal(path, "quizEvents/event");
          return { id: "event", exists: true, data: () => ({ status, currentQuestionId: null }) };
        } }),
        collection: (path) => {
          const snapshot = async () => {
            reads.push(path);
            return { docs: path.endsWith("/participants") ? [{ id: "person", exists: true, data: () => ({ displayName: "Member", teamId: "A" }) }] : [] };
          };
          return { get: snapshot, orderBy: () => ({ get: snapshot }) };
        },
      }),
    });
    const prestart = ["registration", "entryClosed"].includes(status);
    assert.equal(reads.includes("quizEvents/event/participants"), prestart);
    assert.equal(result.participants.length, prestart ? 1 : 0);
  }
});

test("projection returns sponsors in the same shape as the console", async () => {
  const sponsor = {
    id: "sponsor", exists: true,
    data: () => ({ name: { ja: "スポンサー", en: "Sponsor" }, updatedAt: Timestamp.fromMillis(0) }),
  };
  const read = (view) => administerEvent(admin, { environment: "prod", action: "read", payload: { view, eventId: "event" } }, {
    adminDb, getUser: async () => ({ disabled: false }),
    target: () => ({
      doc: (path) => ({ get: async () => {
        assert.equal(path, "quizEvents/event");
        return { id: "event", exists: true, data: () => ({ status: "inProgress", currentQuestionId: null }) };
      } }),
      collection: (path) => {
        const snapshot = async () => ({ docs: path === "sponsors" ? [sponsor] : [] });
        return { get: snapshot, orderBy: () => ({ get: snapshot }) };
      },
    }),
  });
  const [projection, quizConsole] = await Promise.all([read("quizProjection"), read("quizConsole")]);
  assert.deepEqual(projection.sponsors, [
    { id: "sponsor", name: { ja: "スポンサー", en: "Sponsor" }, updatedAt: "1970-01-01T00:00:00.000Z" },
  ]);
  assert.deepEqual(projection.sponsors, quizConsole.sponsors);
});

function participantIdentityFixture(environment) {
  const records = new Map(Object.entries({
    "quizEvents/event": { status: "registration", currentQuestionId: null },
    "quizEvents/event/participants/nickname": { displayName: "公開ニックネーム", teamId: "A" },
    "quizEvents/event/participants/profile": { displayName: "参加者" },
    "quizEvents/event/participants/account": { displayName: "  " },
    "quizEvents/event/participants/missing": {},
    "quizEvents/event/participants/generic-profile": { displayName: "参加者" },
    "quizEvents/event/participants/email-only": { displayName: "参加者" },
    "quizEvents/event/participants/invalid-fields": { displayName: 123 },
    "quizEvents/event/participantAccounts/nickname": {
      accountName: `${environment} Account`, email: ` ${environment}@example.test `,
      photoUrl: "https://example.test/private-photo", signInProvider: "google.com", uid: "untrusted-uid",
    },
    "quizEvents/event/participantAccounts/profile": { accountName: "アカウント名", email: "profile@example.test" },
    "quizEvents/event/participantAccounts/account": { accountName: ` ${environment} 氏名 ` },
    "quizEvents/event/participantAccounts/generic-profile": { accountName: "氏名あり" },
    "quizEvents/event/participantAccounts/email-only": { email: "known@example.test" },
    "quizEvents/event/participantAccounts/invalid-fields": { accountName: {}, email: false },
    "quizEvents/event/participantAccounts/orphan": { accountName: "Not a participant", email: "orphan@example.test" },
    "users/nickname": { displayName: "プロフィールで上書きしない" },
    "users/profile": { displayName: `${environment} プロフィール名` },
    "users/generic-profile": { displayName: "参加者" },
  }));
  const reads = [];
  const snapshot = (path) => ({
    id: path.split("/").at(-1), exists: records.has(path),
    data: () => records.get(path), get: (field) => records.get(path)?.[field],
  });
  const db = {
    doc: (path) => ({ path, get: async () => { reads.push(path); return snapshot(path); } }),
    getAll: async (...refs) => refs.map((ref) => { reads.push(ref.path); return snapshot(ref.path); }),
    collection: (path) => {
      const get = async () => {
        reads.push(path);
        return { docs: [...records.keys()].filter((key) => key.startsWith(`${path}/`) && !key.slice(path.length + 1).includes("/"))
          .map(snapshot) };
      };
      return { get, orderBy: () => ({ get }) };
    },
  };
  return { db, reads, records };
}

test("the console identifies existing participants from only the selected environment without rewriting public nicknames", async () => {
  for (const environment of ["stg", "prod"]) {
    const fixture = participantIdentityFixture(environment);
    const result = await administerEvent(admin, {
      environment, action: "read", payload: { view: "quizConsole", eventId: "event" },
    }, {
      adminDb, getUser: async (uid) => { assert.equal(uid, admin.uid); return { disabled: false }; },
      target: (selected) => { assert.equal(selected, environment); return fixture.db; },
    });
    assert.deepEqual(result.participantAccounts, [
      { id: "nickname", displayName: "公開ニックネーム", accountName: `${environment} Account`, email: `${environment}@example.test` },
      { id: "profile", displayName: `${environment} プロフィール名`, accountName: "アカウント名", email: "profile@example.test" },
      { id: "account", displayName: `${environment} 氏名`, accountName: `${environment} 氏名`, email: null },
      { id: "missing", displayName: "参加者", accountName: null, email: null },
      { id: "generic-profile", displayName: "氏名あり", accountName: "氏名あり", email: null },
      { id: "email-only", displayName: "参加者", accountName: null, email: "known@example.test" },
      { id: "invalid-fields", displayName: "参加者", accountName: null, email: null },
    ]);
    assert.equal(result.participants.find((participant) => participant.id === "profile").displayName, "参加者");
    assert.equal(result.participants.find((participant) => participant.id === "account").displayName, "  ");
    assert.equal(fixture.reads.includes("users/nickname"), false);
    assert.equal(fixture.reads.includes("quizEvents/event/participantAccounts/orphan"), false);
    assert.equal(result.participants.some((participant) => "email" in participant || "accountName" in participant), false);
  }
});

test("projection and question snapshots never read or return private participant identities", async () => {
  for (const view of ["quizProjection", "quizQuestion"]) {
    const fixture = participantIdentityFixture("prod");
    const result = await administerEvent(admin, {
      environment: "prod", action: "read", payload: { view, eventId: "event" },
    }, { adminDb, getUser: async () => ({ disabled: false }), target: () => fixture.db });
    assert.equal("participantAccounts" in result, false);
    assert.equal(fixture.reads.some((path) => path.startsWith("users/") || path.includes("/participantAccounts")), false);
    assert.equal(JSON.stringify(result).includes("@example.test"), false);
    if (view === "quizProjection") {
      assert.equal(result.participants.find((participant) => participant.id === "profile").displayName, "参加者");
    }
  }
});
