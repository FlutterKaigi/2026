const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { test } = require("node:test");
const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

function localHost(name, fallback) {
  const value = process.env[name] ?? fallback;
  assert.match(value, /^(localhost|127\.0\.0\.1|\[::1\]):\d+$/);
  process.env[name] = value;
  return value;
}
const authHost = localHost("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099");
localHost("FIRESTORE_EMULATOR_HOST", "127.0.0.1:8080");
const functionsHost = localHost("FUNCTIONS_EMULATOR_HOST", "127.0.0.1:5001");
const projectId = process.env.SUPPORT_LT_TEST_PROJECT_ID ?? "dev-flutterkaigi-2026";

test("the callable enforces source login, local-only routing, and source admin revocation", async () => {
  const uid = `gateway-${randomUUID()}`;
  const eventId = `gateway-event-${randomUUID()}`;
  const app = initializeApp({ projectId }, uid);
  const db = getFirestore(app), auth = getAuth(app);
  const password = randomUUID();
  const call = async (data, token) => {
    const response = await fetch(`http://${functionsHost}/${projectId}/asia-northeast1/eventAdministration`, {
      method: "POST", headers: { "Content-Type": "application/json", ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      body: JSON.stringify({ data }),
    });
    return response.json();
  };
  try {
    const user = await auth.createUser({ uid, email: `${uid}@flutterkaigi.jp`, emailVerified: true, password });
    await db.doc(`admins/${uid}`).set({});
    const login = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-key`, {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: user.email, password, returnSecureToken: true }),
    });
    const token = (await login.json()).idToken;
    assert.ok(token);
    assert.equal((await call({ environment: "dev", action: "clock" })).error.status, "UNAUTHENTICATED");
    for (const environment of ["stg", "prod"]) {
      assert.equal((await call({ environment, action: "clock" }, token)).error.status, "INVALID_ARGUMENT");
    }
    const created = await call({ environment: "dev", action: "saveEvent", payload: {
      eventId, title: { ja: "ローカル大会", en: "Local quiz" }, capacity: 3, sponsorIds: [], teamNamePool: [],
    } }, token);
    assert.deepEqual(created.result, { eventId });
    const published = await call({ environment: "dev", action: "quizOperation", payload: {
      eventId, operation: "publish", operationId: randomUUID(),
    } }, token);
    assert.equal(published.error, undefined, JSON.stringify(published));
    assert.equal((await db.doc(`quizEvents/${eventId}`).get()).get("status"), "published");
    await db.doc(`admins/${uid}`).delete();
    const denied = await call({ environment: "dev", action: "read", payload: { view: "quizConsole", eventId } }, token);
    assert.equal(denied.error.status, "PERMISSION_DENIED");
  } finally {
    await db.recursiveDelete(db.doc(`quizEvents/${eventId}`));
    await db.doc(`admins/${uid}`).delete();
    await auth.deleteUser(uid);
    await deleteApp(app);
  }
});
