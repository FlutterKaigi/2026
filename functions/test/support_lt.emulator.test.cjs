const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { after, before, test } = require("node:test");
const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { registerSupportLtForUser } = require("../lib/support_lt_service.js");

// All three endpoints are forced to loopback, including Admin SDK writes.
function emulatorHost(name, fallback) {
  const host = process.env[name] ?? fallback;
  assert.match(host, /^(localhost|127\.0\.0\.1|\[::1\]):[0-9]+$/, `${name} must point to a local emulator`);
  process.env[name] = host;
  return host;
}

const authHost = emulatorHost("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099");
const firestoreHost = emulatorHost("FIRESTORE_EMULATOR_HOST", "127.0.0.1:8080");
const functionsHost = emulatorHost("FUNCTIONS_EMULATOR_HOST", "127.0.0.1:5001");
const projectId = process.env.SUPPORT_LT_TEST_PROJECT_ID ?? "dev-flutterkaigi-2026";
const app = initializeApp({ projectId }, `support-lt-test-${randomUUID()}`);
const auth = getAuth(app);
const db = getFirestore(app);
const documentsUrl = `http://${firestoreHost}/v1/projects/${projectId}/databases/(default)/documents`;
const prefix = `lt-test-${randomUUID().slice(0, 8)}`;
const users = [];
let originalSettings;
let settingsRead = false;
let admin;
let attendee;
let stranger;
let unverified;
let wrongDomain;
let unlisted;
let anonymous;

async function createUser(label, options = {}) {
  const password = randomUUID();
  const user = await auth.createUser({
    uid: `${prefix}-${label}`,
    email: `${prefix}-${label}@${options.domain ?? "example.test"}`,
    emailVerified: options.verified ?? true,
    password,
    ...(options.displayName ? { displayName: options.displayName } : {}),
  });
  users.push(user.uid);
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-test-key`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: user.email, password, returnSecureToken: true }),
  });
  assert.equal(response.status, 200, `Emulator sign-in failed for ${label}`);
  const body = await response.json();
  return { uid: user.uid, token: body.idToken };
}

async function call(name, user, data) {
  const response = await fetch(`http://${functionsHost}/${projectId}/asia-northeast1/${name}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(user ? { Authorization: `Bearer ${user.token}` } : {}),
    },
    body: JSON.stringify({ data }),
  });
  const body = await response.json();
  return { status: response.status, ...body };
}

async function expectCallError(name, user, data, status) {
  const response = await call(name, user, data);
  assert.equal(response.error?.status, status, `Unexpected callable result: ${JSON.stringify(response)}`);
}

async function clientRequest(path, user, method = "GET", body) {
  return fetch(`${documentsUrl}/${path}`, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(user ? { Authorization: `Bearer ${user.token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
}

async function waitUntil(predicate, description) {
  const deadline = Date.now() + 20_000;
  while (Date.now() < deadline) {
    if (await predicate()) return;
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  assert.fail(`Timed out waiting for ${description}`);
}

before(async () => {
  originalSettings = (await db.doc("supportLtSettings/current").get()).data();
  settingsRead = true;
  [admin, attendee, stranger, unverified, wrongDomain, unlisted] = await Promise.all([
    createUser("admin", { domain: "flutterkaigi.jp" }),
    createUser("attendee", { displayName: "Emulator auth name" }),
    createUser("stranger"),
    createUser("unverified", { domain: "flutterkaigi.jp", verified: false }),
    createUser("wrong-domain", { domain: "example.test" }),
    createUser("unlisted", { domain: "flutterkaigi.jp" }),
  ]);
  await Promise.all([admin, unverified, wrongDomain].map((user) => db.doc(`admins/${user.uid}`).set({})));
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=local-test-key`, {
    method: "POST", headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ returnSecureToken: true }),
  });
  assert.equal(response.status, 200);
  const result = await response.json();
  anonymous = { uid: result.localId, token: result.idToken };
  users.push(anonymous.uid);
});

after(async () => {
  const batch = db.batch();
  for (const uid of users) {
    for (const collection of ["admins", "users", "supportLtRegistrations", "supportLtRegistrationAttempts"]) {
      batch.delete(db.doc(`${collection}/${uid}`));
    }
  }
  batch.delete(db.doc("supportLtSettings/attempts"));
  if (settingsRead) {
    if (originalSettings) batch.set(db.doc("supportLtSettings/current"), originalSettings);
    else batch.delete(db.doc("supportLtSettings/current"));
  }
  await batch.commit();
  await Promise.all(users.map((uid) => auth.deleteUser(uid).catch((error) => {
    if (error.code !== "auth/user-not-found") throw error;
  })));
  await deleteApp(app);
});

test("Support LT real callable, transaction, Auth cleanup, and Firestore security integration", async (t) => {
  let liveCode;
  let registeredAt;

  await t.test("callables reject missing auth, anonymous users, and unqualified admins", async () => {
    await expectCallError("issueSupportLtCode", null, {}, "UNAUTHENTICATED");
    await expectCallError("registerSupportLt", null, { code: "000000" }, "UNAUTHENTICATED");
    await expectCallError("registerSupportLt", anonymous, { code: "000000" }, "PERMISSION_DENIED");
    for (const user of [attendee, anonymous, unverified, wrongDomain, unlisted]) {
      await expectCallError("issueSupportLtCode", user, {}, "PERMISSION_DENIED");
    }
    await expectCallError("issueSupportLtCode", admin, { rotate: "true" }, "INVALID_ARGUMENT");
    await expectCallError("registerSupportLt", attendee, { code: 123456 }, "INVALID_ARGUMENT");
  });

  await t.test("simultaneous issue calls reuse one code and each explicit rotation invalidates its predecessor", async () => {
    await db.doc("supportLtSettings/current").delete();
    const responses = await Promise.all(Array.from({ length: 4 }, () => call("issueSupportLtCode", admin, {})));
    const codes = responses.map((response) => response.result?.code);
    assert.equal(new Set(codes).size, 1);
    assert.match(codes[0], /^[0-9]{6}$/);
    assert.deepEqual(Object.keys(responses[0].result).sort(), ["code", "issuedAt"]);
    const rotations = await Promise.all(Array.from({ length: 3 }, () => call("issueSupportLtCode", admin, { rotate: true })));
    for (const rotation of rotations) assert.match(rotation.result?.code, /^[0-9]{6}$/);
    const settings = (await db.doc("supportLtSettings/current").get()).data();
    assert.equal(settings.version, 4);
    assert.ok(rotations.some((response) => response.result.code === settings.code));
    // Only the immediate predecessor must differ; codes from older rotations
    // can eventually recur in the finite six-digit space.
    const finalRotation = await call("issueSupportLtCode", admin, { rotate: true });
    liveCode = finalRotation.result.code;
    assert.notEqual(liveCode, settings.code);
    assert.equal((await db.doc("supportLtSettings/current").get()).data().version, 5);
    await expectCallError("registerSupportLt", attendee, { code: settings.code }, "NOT_FOUND");
  });

  await t.test("six concurrent registration calls without a profile create one immutable registration", async () => {
    assert.equal((await db.doc(`users/${attendee.uid}`).get()).exists, false);
    const responses = await Promise.all(Array.from({ length: 6 }, () => call("registerSupportLt", attendee, { code: liveCode })));
    assert.equal(responses.filter((response) => response.result?.alreadyRegistered === false).length, 1);
    assert.equal(responses.filter((response) => response.result?.alreadyRegistered === true).length, 5);
    assert.equal(new Set(responses.map((response) => response.result?.registeredAt)).size, 1);
    registeredAt = responses[0].result.registeredAt;
    const registration = (await db.doc(`supportLtRegistrations/${attendee.uid}`).get()).data();
    assert.equal(registration.displayName, "Emulator auth name");
    assert.equal(registration.registeredAt.toMillis(), registeredAt);
    assert.equal(registration.codeVersion, 5);
    assert.equal((await db.doc(`supportLtRegistrationAttempts/${attendee.uid}`).get()).exists, false);
  });

  await t.test("participants get only their own entry; only qualified admins read code or list attendees", async () => {
    assert.equal((await clientRequest(`supportLtRegistrations/${attendee.uid}`, attendee)).status, 200);
    assert.equal((await clientRequest(`supportLtRegistrations/${attendee.uid}`, admin)).status, 200);
    assert.equal((await clientRequest("supportLtSettings/current", admin)).status, 200);
    const list = await clientRequest("supportLtRegistrations", admin);
    assert.equal(list.status, 200);
    assert.ok((await list.json()).documents.some((document) => document.name.endsWith(`/${attendee.uid}`)));
    for (const user of [null, anonymous, attendee, stranger, unverified, wrongDomain, unlisted]) {
      assert.equal((await clientRequest("supportLtSettings/current", user)).status, 403);
      assert.equal((await clientRequest("supportLtRegistrations", user)).status, 403);
      if (user !== attendee) {
        assert.equal((await clientRequest(`supportLtRegistrations/${attendee.uid}`, user)).status, 403);
      }
    }
    const ownQuery = await fetch(`${documentsUrl}:runQuery`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${attendee.token}` },
      body: JSON.stringify({ structuredQuery: {
        from: [{ collectionId: "supportLtRegistrations" }],
        where: { fieldFilter: {
          field: { fieldPath: "__name__" }, op: "EQUAL",
          value: { referenceValue: `projects/${projectId}/databases/(default)/documents/supportLtRegistrations/${attendee.uid}` },
        } },
      } }),
    });
    assert.equal(ownQuery.status, 403);
  });

  await t.test("all clients including admins are denied direct writes, deletes, and attempts reads", async () => {
    await db.doc(`supportLtRegistrationAttempts/${attendee.uid}`).set({ failCount: 1, windowStartedAt: Timestamp.now() });
    for (const user of [null, anonymous, attendee, stranger, admin]) {
      for (const path of ["supportLtSettings/current", "supportLtSettings/attempts", `supportLtRegistrations/${attendee.uid}`, `supportLtRegistrationAttempts/${attendee.uid}`]) {
        assert.equal((await clientRequest(path, user, "PATCH", { fields: { forged: { booleanValue: true } } })).status, 403);
        assert.equal((await clientRequest(path, user, "DELETE")).status, 403);
      }
      assert.equal((await clientRequest(`supportLtRegistrationAttempts/${attendee.uid}`, user)).status, 403);
    }
  });

  await t.test("wrong codes persist attempts, the tenth failure locks the uid, and the block expires", async () => {
    const issued = await call("issueSupportLtCode", admin, {});
    assert.equal(issued.result.code, liveCode, "the current code is reused without an expiry");
    const wrongCode = liveCode === "111111" ? "222222" : "111111";
    // Sequential on purpose: a burst of calls from one account contends for
    // its registration lock, and slow CI runners exhaust the SDK's retries.
    // Concurrency on the success path is covered by the six-call test above.
    for (let failure = 1; failure <= 11; failure++) {
      await expectCallError("registerSupportLt", stranger, { code: wrongCode }, failure < 10 ? "NOT_FOUND" : "RESOURCE_EXHAUSTED");
    }
    const attemptsRef = db.doc(`supportLtRegistrationAttempts/${stranger.uid}`);
    const attempts = (await attemptsRef.get()).data();
    assert.equal(attempts.failCount, 10);
    assert.ok(attempts.blockedUntil.toMillis() > Date.now());
    await expectCallError("registerSupportLt", stranger, { code: liveCode }, "RESOURCE_EXHAUSTED");
    await attemptsRef.update({ blockedUntil: Timestamp.fromMillis(Date.now() - 1) });
    const registered = await call("registerSupportLt", stranger, { code: liveCode });
    assert.equal(registered.result.alreadyRegistered, false);
    assert.equal((await db.doc(`supportLtRegistrations/${stranger.uid}`).get()).data().displayName, stranger.uid);
    assert.equal((await attemptsRef.get()).exists, false);
    const shared = (await db.doc("supportLtSettings/attempts").get()).data();
    assert.ok(Object.values(shared.counts).reduce((sum, count) => sum + count, 0) >= 10,
      "shared counter tracks every account's failures");
    const repeated = await call("registerSupportLt", attendee, { code: wrongCode });
    assert.deepEqual(repeated.result, { registeredAt, alreadyRegistered: true });
  });

  await t.test("a shared block stops every account and rotation lifts it", async () => {
    const blocker = await createUser("blocker");
    // Seed this and the next ten-minute bucket so a bucket boundary during
    // the test cannot lift the block early.
    const bucket = Math.floor(Date.now() / 600_000);
    await db.doc("supportLtSettings/attempts").set({ counts: { [bucket]: 199, [bucket + 1]: 199 } });
    const wrongCode = liveCode === "111111" ? "222222" : "111111";
    // The 200th failure is still reported as a wrong code; the block applies
    // to every call after it, including correct codes from other accounts.
    await expectCallError("registerSupportLt", blocker, { code: wrongCode }, "NOT_FOUND");
    assert.equal((await db.doc("supportLtSettings/attempts").get()).data().counts[bucket], 200);
    const fresh = await createUser("blocked-bystander");
    await expectCallError("registerSupportLt", fresh, { code: liveCode }, "RESOURCE_EXHAUSTED");
    await expectCallError("registerSupportLt", blocker, { code: wrongCode }, "RESOURCE_EXHAUSTED");
    assert.equal((await db.doc(`supportLtRegistrationAttempts/${fresh.uid}`).get()).exists, false);
    assert.equal((await db.doc(`supportLtRegistrationAttempts/${blocker.uid}`).get()).data().failCount, 1,
      "a shared block records no further per-user failures");
    const rotated = await call("issueSupportLtCode", admin, { rotate: true });
    liveCode = rotated.result.code;
    assert.equal((await db.doc("supportLtSettings/attempts").get()).exists, false);
    const registered = await call("registerSupportLt", fresh, { code: liveCode });
    assert.equal(registered.result.alreadyRegistered, false);
  });

  await t.test("Auth account deletion cleans a no-profile attendee via the actual trigger", async () => {
    assert.equal((await db.doc(`users/${attendee.uid}`).get()).exists, false);
    await auth.deleteUser(attendee.uid);
    await waitUntil(async () => {
      const [registration, attempts] = await Promise.all([
        db.doc(`supportLtRegistrations/${attendee.uid}`).get(),
        db.doc(`supportLtRegistrationAttempts/${attendee.uid}`).get(),
      ]);
      return !registration.exists && !attempts.exists;
    }, "Auth deletion trigger to remove registration and failed attempts");
    assert.equal((await db.doc(`supportLtRegistrations/${stranger.uid}`).get()).exists, true);
  });

  await t.test("Auth deletion during registration cannot run cleanup before the locked transaction commits", async () => {
    const racing = await createUser("deletion-race");
    let cleanup;
    const registered = await registerSupportLtForUser({ uid: racing.uid, token: {} }, { code: liveCode }, {
      db,
      getUser: async (uid) => {
        const user = await auth.getUser(uid);
        // Auth was active when checked, then disappears while the transaction
        // still holds its registration read lock. Queue the same cleanup batch
        // as onDelete and prove it cannot overtake the registration write.
        await auth.deleteUser(uid);
        const batch = db.batch();
        batch.delete(db.doc(`supportLtRegistrations/${uid}`));
        batch.delete(db.doc(`supportLtRegistrationAttempts/${uid}`));
        cleanup = batch.commit();
        const first = await Promise.race([
          cleanup.then(() => "cleanup-finished"),
          new Promise((resolve) => setTimeout(() => resolve("registration-locked"), 200)),
        ]);
        assert.equal(first, "registration-locked");
        return user;
      },
    });
    assert.equal(registered.alreadyRegistered, false);
    await cleanup;
    await waitUntil(async () => !(await db.doc(`supportLtRegistrations/${racing.uid}`).get()).exists,
      "queued Auth cleanup after registration commit");
    assert.equal((await db.doc(`supportLtRegistrationAttempts/${racing.uid}`).get()).exists, false);
  });

  await t.test("a deleted account's still-valid ID token cannot recreate registration or failed attempts", async () => {
    await expectCallError("registerSupportLt", attendee, { code: liveCode }, "UNAUTHENTICATED");
    const wrongCode = liveCode === "111111" ? "222222" : "111111";
    await expectCallError("registerSupportLt", attendee, { code: wrongCode }, "UNAUTHENTICATED");
    assert.equal((await db.doc(`supportLtRegistrations/${attendee.uid}`).get()).exists, false);
    assert.equal((await db.doc(`supportLtRegistrationAttempts/${attendee.uid}`).get()).exists, false);
  });

  await t.test("disabled attendees keep their registration and deleted admins cannot use old ID tokens", async () => {
    await auth.updateUser(stranger.uid, { disabled: true });
    await expectCallError("registerSupportLt", stranger, { code: liveCode }, "PERMISSION_DENIED");
    assert.equal((await db.doc(`supportLtRegistrations/${stranger.uid}`).get()).exists, true);
    await auth.deleteUser(admin.uid);
    const previousSettings = (await db.doc("supportLtSettings/current").get()).data();
    await expectCallError("issueSupportLtCode", admin, { rotate: true }, "UNAUTHENTICATED");
    assert.deepEqual((await db.doc("supportLtSettings/current").get()).data(), previousSettings);
  });
});
