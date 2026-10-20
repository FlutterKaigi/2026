const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { test } = require("node:test");
const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { issueSupportLtCodeForUser, registerSupportLtForUser } = require("../lib/support_lt_service.js");

for (const [name, fallback] of [
  ["FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099"],
  ["FIRESTORE_EMULATOR_HOST", "127.0.0.1:8080"],
]) {
  const host = process.env[name] ?? fallback;
  assert.match(host, /^(localhost|127\.0\.0\.1|\[::1\]):[0-9]+$/, `${name} must point to a local emulator`);
  process.env[name] = host;
}

function deferred() {
  let resolve;
  const promise = new Promise((complete) => { resolve = complete; });
  return { promise, resolve };
}

// Delay only the post-commit increment RPC. Firestore transaction reads,
// locks, retries, commits, and Auth account lookups remain real.
function delayCounterWrites(db, gate, onQueued) {
  return new Proxy(db, {
    get(target, key) {
      if (key === "doc") return (path) => {
        const reference = target.doc(path);
        if (path !== "supportLtSettings/attempts") return reference;
        return new Proxy(reference, {
          get(ref, member) {
            if (member === "set") return async (...args) => {
              onQueued();
              await gate;
              return ref.set(...args);
            };
            const value = ref[member];
            return typeof value === "function" ? value.bind(ref) : value;
          },
        });
      };
      const value = target[key];
      return typeof value === "function" ? value.bind(target) : value;
    },
  });
}

test("Support LT rotation isolates 200 delayed old-code failures with real Auth and Firestore", { timeout: 60_000 }, async () => {
  // A dedicated emulator project lets this run alongside the callable suites
  // without changing their global Support LT settings or issuing real traffic.
  const projectId = `demo-lt-race-${randomUUID().slice(0, 8)}`;
  const app = initializeApp({ projectId }, projectId);
  const auth = getAuth(app);
  const db = getFirestore(app);
  const users = [];
  const releaseWrites = deferred();
  const allWritesQueued = deferred();
  let pending = [];
  let queued = 0;
  let queueTimeout;
  const now = Date.now();
  const bucket = Math.floor(now / 600_000);
  const dependencies = { db, getUser: (uid) => auth.getUser(uid), now: () => now, randomInt: () => 0 };
  async function createUser(uid, staff = false) {
    const user = await auth.createUser({
      uid, email: `${uid}@${staff ? "flutterkaigi.jp" : "example.test"}`, emailVerified: true,
    });
    users.push(user.uid);
    return { uid: user.uid, token: { email: user.email, email_verified: true } };
  }
  try {
    const admin = await createUser("rotation-admin", true);
    await db.doc(`admins/${admin.uid}`).set({});
    const createdGuessers = await Promise.allSettled(Array.from({ length: 200 }, (_, index) => createUser(`guesser-${index}`)));
    for (const result of createdGuessers) {
      if (result.status === "rejected") throw result.reason;
    }
    const guessers = createdGuessers.map((result) => result.value);
    const fresh = await createUser("fresh-attendee");
    const bystander = await createUser("blocked-bystander");
    const original = await issueSupportLtCodeForUser(admin, {}, dependencies);
    const delayedDb = delayCounterWrites(db, releaseWrites.promise, () => {
      queued += 1;
      if (queued === 200) allWritesQueued.resolve();
    });
    const wrongCode = original.code === "111111" ? "222222" : "111111";
    pending = guessers.map((user) => registerSupportLtForUser(user, { code: wrongCode }, {
      ...dependencies, db: delayedDb,
    }).then(() => "unexpected-success", (error) => error.code));
    await Promise.race([
      allWritesQueued.promise,
      new Promise((_, reject) => {
        queueTimeout = setTimeout(() => reject(new Error(`Only ${queued}/200 old failures reached the write gate`)), 30_000);
      }),
    ]);
    clearTimeout(queueTimeout);
    const rotated = await issueSupportLtCodeForUser(admin, { rotate: true }, dependencies);
    assert.notEqual(rotated.code, original.code);
    releaseWrites.resolve();
    assert.deepEqual(await Promise.all(pending), Array(200).fill("not-found"));
    assert.equal((await registerSupportLtForUser(fresh, { code: rotated.code }, dependencies)).alreadyRegistered, false);
    assert.deepEqual((await db.doc("supportLtSettings/attempts").get()).data(), {
      resetCodeVersion: 2, counts: { [`v1_${bucket}`]: 200 },
    });

    // Positive control: only the current code's 200th failure closes its
    // budget, and another rotation remains a working staff recovery action.
    await db.doc("supportLtSettings/attempts").set({ counts: { [`v2_${bucket}`]: 199 } }, { merge: true });
    await assert.rejects(registerSupportLtForUser(guessers[0], { code: original.code }, dependencies), { code: "not-found" });
    await assert.rejects(registerSupportLtForUser(bystander, { code: rotated.code }, {
      ...dependencies,
      getUser: async () => assert.fail("blocked requests must not perform Auth lookups"),
      db: new Proxy(db, {
        get(target, key) {
          if (key === "runTransaction") return () => assert.fail("blocked requests must not acquire transaction locks");
          const value = target[key];
          return typeof value === "function" ? value.bind(target) : value;
        },
      }),
    }), { code: "resource-exhausted" });
    await assert.rejects(registerSupportLtForUser(bystander, { code: rotated.code }, dependencies), { code: "resource-exhausted" });
    assert.equal((await db.doc(`supportLtRegistrationAttempts/${bystander.uid}`).get()).exists, false);
    const recovered = await issueSupportLtCodeForUser(admin, { rotate: true }, dependencies);
    assert.equal((await registerSupportLtForUser(bystander, { code: recovered.code }, dependencies)).alreadyRegistered, false);
  } finally {
    clearTimeout(queueTimeout);
    releaseWrites.resolve();
    await Promise.allSettled(pending);
    const cleanup = db.batch();
    cleanup.delete(db.doc("supportLtSettings/current"));
    cleanup.delete(db.doc("supportLtSettings/attempts"));
    cleanup.delete(db.doc("admins/rotation-admin"));
    for (const uid of users) {
      cleanup.delete(db.doc(`supportLtRegistrationAttempts/${uid}`));
      cleanup.delete(db.doc(`supportLtRegistrations/${uid}`));
    }
    await cleanup.commit();
    if (users.length > 0) {
      const deleted = await auth.deleteUsers(users);
      assert.equal(deleted.failureCount, 0, "dedicated Auth users are removed");
    }
    await db.terminate();
    await deleteApp(app);
  }
});
