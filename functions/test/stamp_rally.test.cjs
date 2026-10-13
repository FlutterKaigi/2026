const assert = require("node:assert/strict");
const { createHmac } = require("node:crypto");
const { test } = require("node:test");
const { Timestamp } = require("firebase-admin/firestore");
const {
  getStampRallyQrCodesForUser,
  scanStampRallyCodeForUser,
  stampRallyToken,
} = require("../lib/stamp_rally_service.js");

const NOW = 1_800_000_000_000;
const SECRET = "unit-test-secret";
const ADMIN = {
  uid: "admin",
  token: { email: "staff@flutterkaigi.jp", email_verified: true, firebase: { sign_in_provider: "google.com" } },
};
const USER = { uid: "attendee", token: { firebase: { sign_in_provider: "password" } } };
const CARD = `stampRallyCards/${USER.uid}`;

// The contract is HMAC-SHA256(secret, purpose) in lowercase hex; computed
// independently so a change in the service's algorithm fails these tests.
const sign = (purpose, secret = SECRET) => createHmac("sha256", secret).update(purpose).digest("hex");
const stamp = (sponsorId) => sign(`stamp.v1.${sponsorId}`);
const REWARD = sign("reward.v1");
const THANKS = sign("thanks.v1");

// Transactions stage writes until the callback returns, as Firestore does, and
// merge writes apply one nested map level (stamps / rewardsRedeemedAt).
function fixture(entries = {}) {
  const documents = new Map(Object.entries(entries));
  const events = [];
  const snapshot = (path) => ({ exists: documents.has(path), data: () => documents.get(path) });
  const merge = (path, data) => {
    const current = { ...(documents.get(path) ?? {}) };
    for (const [key, value] of Object.entries(data)) {
      current[key] = value instanceof Timestamp ? value : { ...(current[key] ?? {}), ...value };
    }
    documents.set(path, current);
  };
  const collection = (path) => ({
    isCollection: true,
    path,
    doc: (id) => ref(`${path}/${id}`),
    get: async () => ({
      docs: [...documents.keys()]
        .filter((key) => key.startsWith(`${path}/`) && key.split("/").length === path.split("/").length + 1)
        .map((key) => ({ id: key.split("/").at(-1), ...snapshot(key) })),
    }),
  });
  const ref = (path) => ({ path, get: async () => snapshot(path) });
  const db = {
    doc: ref,
    collection,
    runTransaction: async (callback) => {
      const writes = [];
      try {
        const result = await callback({
          get: async (reference) => {
            assert.equal(writes.length, 0, "Firestore reads must precede writes");
            events.push(`read:${reference.path}`);
            return reference.isCollection ? reference.get() : snapshot(reference.path);
          },
          set: (reference, data, options) => {
            assert.equal(options?.merge, true, "card updates must merge");
            writes.push(() => merge(reference.path, data));
          },
        });
        writes.forEach((apply) => apply());
        events.push("transaction-commit");
        return result;
      } catch (error) {
        events.push("transaction-abort");
        throw error;
      }
    },
    batch: () => {
      const writes = [];
      return {
        set: (reference, data) => writes.push(() => merge(reference.path, data)),
        delete: (reference) => writes.push(() => documents.delete(reference.path)),
        commit: async () => { events.push("batch-commit"); writes.forEach((apply) => apply()); },
      };
    },
  };
  return {
    documents,
    events,
    dependencies: {
      db, secret: SECRET, now: () => NOW,
      getUser: async (uid) => { events.push(`auth:${uid}`); return { disabled: false }; },
    },
  };
}

function rally({ isOpen = true, checkpoints = [2, 3], sponsors = ["a", "b", "c", "d"], card } = {}) {
  return fixture({
    "stampRallySettings/current": { checkpoints, isOpen, updatedAt: Timestamp.fromMillis(NOW - 1) },
    ...Object.fromEntries(sponsors.map((id) => [`stampRallySponsors/${id}`, { createdAt: Timestamp.fromMillis(NOW - 1) }])),
    ...(card ? { [CARD]: card } : {}),
  });
}

const at = (millis) => Timestamp.fromMillis(millis);
const scan = (dependencies, token, auth = USER) => scanStampRallyCodeForUser(auth, { token }, dependencies);
const rejectsCode = (promise, code) => assert.rejects(promise, (error) => error.code === code);

test("tokens are the HMAC-SHA256 hex of their purpose", () => {
  assert.equal(stampRallyToken(SECRET, "reward.v1"), REWARD);
  assert.match(REWARD, /^[0-9a-f]{64}$/);
});

test("scanning requires a non-anonymous account and a well-formed token", async () => {
  const { dependencies, events } = rally();
  for (const auth of [undefined, null]) {
    await rejectsCode(scanStampRallyCodeForUser(auth, { token: REWARD }, dependencies), "unauthenticated");
  }
  await rejectsCode(scan(dependencies, REWARD, { uid: "anon", token: { firebase: { sign_in_provider: "anonymous" } } }),
    "permission-denied");
  for (const data of [null, [], {}, { token: 1 }, { token: REWARD, extra: true }, { token: REWARD.toUpperCase() },
    { token: REWARD.slice(1) }, { token: `https://2026-app.flutterkaigi.jp/s/${REWARD}` }]) {
    await rejectsCode(scanStampRallyCodeForUser(USER, data, dependencies), "invalid-argument");
  }
  assert.deepEqual(events, []);
});

test("tokens signed with another secret, for removed sponsors, or for other purposes are not found", async () => {
  const { dependencies, documents } = rally({ sponsors: ["a"] });
  for (const token of [sign("reward.v1", "other-secret"), stamp("removed"), sign("stamp.v2.a"), sign("thanks.v2")]) {
    await rejectsCode(scan(dependencies, token), "not-found");
  }
  assert.equal(documents.has(CARD), false);
});

test("a stamp is recorded once with server time and reports newly reached checkpoints", async () => {
  const { dependencies, documents, events } = rally();
  const first = await scan(dependencies, stamp("a"));
  assert.deepEqual(first, {
    kind: "stamp", sponsorId: "a", alreadyAcquired: false, acquiredAt: NOW, stampCount: 1, newCheckpoints: [], checkpoints: [2, 3],
  });
  // Auth is checked while the card's read lock is held, before anything else is read.
  assert.deepEqual(events.slice(0, 2), [`read:${CARD}`, `auth:${USER.uid}`]);
  assert.deepEqual((await scan(dependencies, stamp("b"))).newCheckpoints, [1]);
  assert.deepEqual((await scan(dependencies, stamp("c"))).newCheckpoints, [2]);
  assert.deepEqual((await scan(dependencies, stamp("d"))).newCheckpoints, []);
  const repeated = await scan(dependencies, stamp("a"));
  assert.equal(repeated.alreadyAcquired, true);
  assert.equal(repeated.stampCount, 4);
  assert.deepEqual(repeated.newCheckpoints, []);
  assert.deepEqual(Object.keys(documents.get(CARD).stamps).sort(), ["a", "b", "c", "d"]);
  assert.equal(documents.get(CARD).updatedAt.toMillis(), NOW);
});

test("one stamp can reach several checkpoints at once", async () => {
  const { dependencies } = rally({ checkpoints: [1, 1, 5] });
  assert.deepEqual((await scan(dependencies, stamp("a"))).newCheckpoints, [1, 2]);
});

test("a closed rally rejects new stamps but still reports acquired ones", async () => {
  const card = { stamps: { a: at(NOW - 100) } };
  const { dependencies, documents } = rally({ isOpen: false, card });
  await rejectsCode(scan(dependencies, stamp("b")), "failed-precondition");
  assert.equal((await scan(dependencies, stamp("a"))).acquiredAt, NOW - 100);
  assert.deepEqual(Object.keys(documents.get(CARD).stamps), ["a"]);
  // A missing settings document means the rally is closed.
  const missing = fixture({ "stampRallySponsors/a": {} });
  await rejectsCode(scan(missing.dependencies, stamp("a")), "failed-precondition");
});

test("missing checkpoints fall back to 7, 14 and 22", async () => {
  const stamps = Object.fromEntries(Array.from({ length: 13 }, (_, i) => [`s${i}`, at(NOW - 1)]));
  const { dependencies } = fixture({
    "stampRallySettings/current": { isOpen: true },
    "stampRallySponsors/new": {},
    [CARD]: { stamps },
  });
  const result = await scan(dependencies, stamp("new"));
  assert.deepEqual(result.checkpoints, [7, 14, 22]);
  assert.deepEqual(result.newCheckpoints, [2]);
});

test("rewards redeem only achieved, unredeemed checkpoints, also while the rally is closed", async () => {
  const card = { stamps: { a: at(1), b: at(2), c: at(3) }, rewardsRedeemedAt: { 1: at(NOW - 50) } };
  const { dependencies, documents } = rally({ isOpen: false, checkpoints: [2, 3, 4], card });
  const first = await scan(dependencies, REWARD);
  assert.deepEqual(first, {
    kind: "reward", redeemedCheckpoints: [2], redeemedAt: NOW, stampCount: 3, checkpoints: [2, 3, 4],
    rewardsRedeemedAt: { 1: NOW - 50, 2: NOW },
  });
  assert.equal(documents.get(CARD).rewardsRedeemedAt[2].toMillis(), NOW);
  const second = await scan(dependencies, REWARD);
  assert.deepEqual(second.redeemedCheckpoints, []);
  assert.equal(second.redeemedAt, null);
  assert.deepEqual(second.rewardsRedeemedAt, { 1: NOW - 50, 2: NOW });
});

test("a reward scan without any checkpoint creates no card", async () => {
  const { dependencies, documents } = rally();
  const result = await scan(dependencies, REWARD);
  assert.deepEqual(result, {
    kind: "reward", redeemedCheckpoints: [], redeemedAt: null, stampCount: 0, checkpoints: [2, 3], rewardsRedeemedAt: {},
  });
  assert.equal(documents.has(CARD), false);
});

test("the thanks card is redeemed once regardless of stamps or the open state", async () => {
  const { dependencies, documents } = rally({ isOpen: false });
  assert.deepEqual(await scan(dependencies, THANKS), { kind: "thanksCard", alreadyRedeemed: false, redeemedAt: NOW });
  dependencies.now = () => NOW + 1000;
  assert.deepEqual(await scan(dependencies, THANKS), { kind: "thanksCard", alreadyRedeemed: true, redeemedAt: NOW });
  assert.equal(documents.get(CARD).thanksCardRedeemedAt.toMillis(), NOW);
});

test("a deleted account is rejected and its data is cleaned up after rollback", async () => {
  const { dependencies, documents, events } = rally({ card: { stamps: { a: at(1) } } });
  dependencies.getUser = async () => { throw Object.assign(new Error("gone"), { code: "auth/user-not-found" }); };
  await rejectsCode(scan(dependencies, stamp("b")), "unauthenticated");
  assert.deepEqual(events.slice(-2), ["transaction-abort", "batch-commit"]);
  assert.equal(documents.has(CARD), false);
});

test("a disabled account is rejected without losing its card", async () => {
  const { dependencies, documents } = rally({ card: { stamps: { a: at(1) } } });
  dependencies.getUser = async () => ({ disabled: true });
  await rejectsCode(scan(dependencies, stamp("b")), "permission-denied");
  assert.deepEqual(Object.keys(documents.get(CARD).stamps), ["a"]);
});

test("exhausted transaction retries are reported as aborted", async () => {
  const { dependencies } = rally();
  dependencies.db.runTransaction = async () => { throw Object.assign(new Error("contention"), { code: 10 }); };
  await rejectsCode(scan(dependencies, stamp("a")), "aborted");
});

test("QR codes are issued only to active admins and cover every target sponsor", async () => {
  const { dependencies } = rally({ sponsors: ["b", "a"] });
  await rejectsCode(getStampRallyQrCodesForUser(null, {}, dependencies), "unauthenticated");
  await rejectsCode(getStampRallyQrCodesForUser(USER, {}, dependencies), "permission-denied");
  await rejectsCode(getStampRallyQrCodesForUser({ uid: "admin", token: { ...ADMIN.token, email_verified: false } }, {}, dependencies),
    "permission-denied");
  await rejectsCode(getStampRallyQrCodesForUser(ADMIN, {}, dependencies), "permission-denied");
  const admin = rally({ sponsors: ["b", "a"] });
  admin.documents.set("admins/admin", {});
  await rejectsCode(getStampRallyQrCodesForUser(ADMIN, { extra: true }, admin.dependencies), "invalid-argument");
  for (const data of [undefined, null, {}]) {
    assert.deepEqual(await getStampRallyQrCodesForUser(ADMIN, data, admin.dependencies), {
      sponsors: [{ sponsorId: "a", token: stamp("a") }, { sponsorId: "b", token: stamp("b") }],
      reward: REWARD,
      thanksCard: THANKS,
    });
  }
  admin.dependencies.getUser = async () => ({ disabled: true });
  await rejectsCode(getStampRallyQrCodesForUser(ADMIN, {}, admin.dependencies), "permission-denied");
});

test("issued QR codes are accepted by the scanner", async () => {
  const { dependencies, documents } = rally({ sponsors: ["a"] });
  documents.set("admins/admin", {});
  const codes = await getStampRallyQrCodesForUser(ADMIN, {}, dependencies);
  assert.equal((await scan(dependencies, codes.sponsors[0].token)).sponsorId, "a");
  assert.equal((await scan(dependencies, codes.reward)).kind, "reward");
  assert.equal((await scan(dependencies, codes.thanksCard)).kind, "thanksCard");
});
