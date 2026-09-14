const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { after, test } = require("node:test");
const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");

function localHost(name, fallback) {
  const host = process.env[name] ?? fallback;
  assert.match(host, /^(localhost|127\.0\.0\.1|\[::1\]):[0-9]+$/);
  process.env[name] = host;
  return host;
}

const authHost = localHost("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099");
const firestoreHost = localHost("FIRESTORE_EMULATOR_HOST", "127.0.0.1:8080");
const projectId = process.env.SUPPORT_LT_TEST_PROJECT_ID ?? "dev-flutterkaigi-2026";
const app = initializeApp({ projectId }, `sns-post-test-${randomUUID()}`);
const db = getFirestore(app);
const auth = getAuth(app);
const base = `http://${firestoreHost}/v1/projects/${projectId}/databases/(default)/documents`;
const users = [];

async function signUp(anonymous = false) {
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=local-test-key`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      returnSecureToken: true,
      ...(!anonymous ? { email: `sns-${randomUUID()}@example.test`, password: randomUUID() } : {}),
    }),
  });
  assert.equal(response.status, 200);
  const body = await response.json();
  const user = { uid: body.localId, token: body.idToken };
  users.push(user);
  return user;
}

function headers(user) {
  return { "Content-Type": "application/json", ...(user ? { Authorization: `Bearer ${user.token}` } : {}) };
}

function write(user, uid, fields = {}, serverTime = true) {
  return fetch(`${base}:commit`, {
    method: "POST",
    headers: headers(user),
    body: JSON.stringify({ writes: [{
      update: {
        name: `projects/${projectId}/databases/(default)/documents/snsPostRegistrations/${uid}`,
        fields: {
          url: { stringValue: "https://x.com/test/status/123" },
          companion: { stringValue: "staff" },
          ...fields,
        },
      },
      ...(serverTime ? { updateTransforms: [{ fieldPath: "updatedAt", setToServerValue: "REQUEST_TIME" }] } : {}),
    }] }),
  });
}

after(async () => {
  for (const user of users) {
    await db.doc(`snsPostRegistrations/${user.uid}`).delete();
    await auth.deleteUser(user.uid).catch((error) => {
      if (error.code !== "auth/user-not-found") throw error;
    });
  }
  await deleteApp(app);
});

test("SNS registrations validate fields, enforce ownership, and follow Auth deletion", async (t) => {
  const owner = await signUp();
  const stranger = await signUp();
  const anonymous = await signUp(true);
  const path = `snsPostRegistrations/${owner.uid}`;

  await t.test("a profile is optional; all five categories save and update a single record", async () => {
    assert.equal((await db.doc(`users/${owner.uid}`).get()).exists, false);
    for (const companion of ["staff", "speaker", "sponsor", "firstTime", "differentCountry"]) {
      const response = await write(owner, owner.uid, { companion: { stringValue: companion } });
      assert.equal(response.status, 200, await response.text());
      const document = (await db.doc(path).get()).data();
      assert.equal(document.companion, companion);
      assert.ok(document.updatedAt.toMillis() > 0);
    }
    assert.equal((await fetch(`${base}/${path}`, { headers: headers(owner) })).status, 200);
  });

  await t.test("other accounts and signed-out clients cannot read or overwrite it", async () => {
    for (const user of [stranger, anonymous, null]) {
      assert.equal((await fetch(`${base}/${path}`, { headers: headers(user) })).status, 403);
      assert.equal((await write(user, owner.uid)).status, 403);
      assert.equal((await fetch(`${base}/${path}`, { method: "DELETE", headers: headers(user) })).status, 403);
    }
    assert.equal((await write(anonymous, anonymous.uid)).status, 403);
    assert.equal((await fetch(`${base}/snsPostRegistrations`, { headers: headers(owner) })).status, 403);
  });

  await t.test("invalid URLs, tags, extra fields and forged timestamps are rejected", async () => {
    const invalid = [
      { url: { stringValue: "javascript:alert(1)" } },
      { url: { stringValue: "https://x.com" } },
      { url: { stringValue: "https://x.com/a b" } },
      { url: { stringValue: "https://user:password@x.com/post/123" } },
      { url: { stringValue: `https://x.com/${"a".repeat(2048)}` } },
      { companion: { stringValue: "anyone" } },
      { companion: { arrayValue: { values: [{ stringValue: "staff" }, { stringValue: "speaker" }] } } },
      { image: { stringValue: "not-a-supported-field" } },
    ];
    for (const fields of invalid) assert.equal((await write(owner, owner.uid, fields)).status, 403);
    assert.equal((await write(owner, owner.uid, { updatedAt: { timestampValue: "2026-01-01T00:00:00Z" } }, false)).status, 403);
    assert.equal((await write(owner, owner.uid, {}, false)).status, 403);
  });

  await t.test("the owner can remove their registration", async () => {
    assert.equal((await fetch(`${base}/${path}`, { method: "DELETE", headers: headers(owner) })).status, 200);
    assert.equal((await db.doc(path).get()).exists, false);
    assert.equal((await write(owner, owner.uid)).status, 200);
  });

  await t.test("deleting an Auth account without a profile cleans up the post", async () => {
    await auth.deleteUser(owner.uid);
    const deadline = Date.now() + 20_000;
    while (Date.now() < deadline && (await db.doc(path).get()).exists) {
      await new Promise((resolve) => setTimeout(resolve, 200));
    }
    assert.equal((await db.doc(path).get()).exists, false);
  });
});
