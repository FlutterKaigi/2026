const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { readFile } = require("node:fs/promises");
const { resolve } = require("node:path");
const { before, after, test } = require("node:test");

const host = process.env.FIRESTORE_EMULATOR_HOST ?? "127.0.0.1:8080";
assert.match(host, /^(localhost|127\.0\.0\.1|\[::1\]):\d+$/);
const projectId = `demo-quiz-deletion-${randomUUID().slice(0, 8)}`;
const origin = `http://${host}`;
const documents = `projects/${projectId}/databases/(default)/documents`;
const base = `${origin}/v1/${documents}`;

// Firestore Emulator accepts unsigned tokens; these never authenticate to Firebase.
function token(uid, email) {
  const issuedAt = Math.floor(Date.now() / 1000);
  const payload = {
    iss: `https://securetoken.google.com/${projectId}`,
    aud: projectId,
    sub: uid,
    user_id: uid,
    iat: issuedAt,
    exp: issuedAt + 3600,
    auth_time: issuedAt,
    email,
    email_verified: true,
    firebase: { sign_in_provider: "password", identities: {} },
  };
  return [
    Buffer.from(JSON.stringify({ alg: "none", typ: "JWT" })).toString("base64url"),
    Buffer.from(JSON.stringify(payload)).toString("base64url"),
    "",
  ].join(".");
}

const admin = token("quiz-admin", "quiz-admin@flutterkaigi.jp");
const attendee = token("attendee", "attendee@example.test");
function headers(auth) {
  return { "Content-Type": "application/json", ...(auth ? { Authorization: `Bearer ${auth}` } : {}) };
}
async function expectStatus(response, status) {
  const body = await response.text();
  assert.equal(response.status, status, body);
  if (status === 403) assert.equal(JSON.parse(body).error.status, "PERMISSION_DENIED");
}
function commit(auth, writes) {
  return fetch(`${base}:commit`, {
    method: "POST", headers: headers(auth), body: JSON.stringify({ writes }),
  });
}
function draftWrite(eventId) {
  return {
    update: {
      name: `${documents}/quizEvents/${eventId}`,
      fields: {
        title: { mapValue: { fields: { ja: { stringValue: "下書き" }, en: { stringValue: "Draft" } } } },
        status: { stringValue: "draft" },
        isPublic: { booleanValue: false },
        currentQuestionId: { nullValue: null },
        capacity: { integerValue: "80" },
        participantCount: { integerValue: "0" },
        revision: { integerValue: "0" },
        sponsorIds: { arrayValue: { values: [] } },
        teamNamePool: { arrayValue: { values: [] } },
      },
    },
    currentDocument: { exists: false },
    updateTransforms: [
      { fieldPath: "createdAt", setToServerValue: "REQUEST_TIME" },
      { fieldPath: "updatedAt", setToServerValue: "REQUEST_TIME" },
    ],
  };
}
async function seedMarker(eventId, status) {
  await expectStatus(await fetch(`${base}/quizEventDeletions/${eventId}`, {
    method: "PATCH", headers: headers("owner"),
    body: JSON.stringify({ fields: { status: { stringValue: status } } }),
  }), 200);
}

before(async () => {
  const content = await readFile(resolve(__dirname, "../../packages/data/firebase/firestore.rules"), "utf8");
  const response = await fetch(`${origin}/emulator/v1/projects/${projectId}:securityRules`, {
    method: "PUT", headers: headers("owner"),
    body: JSON.stringify({ rules: { files: [{ name: "firestore.rules", content }] } }),
  });
  const body = await response.json();
  assert.equal(response.status, 200, JSON.stringify(body));
  assert.deepEqual((body.issues ?? []).filter((issue) => issue.severity === "ERROR"), []);
  await expectStatus(await fetch(`${base}/admins/quiz-admin`, {
    method: "PATCH", headers: headers("owner"), body: JSON.stringify({ fields: {} }),
  }), 200);
});

after(async () => {
  await expectStatus(await fetch(`${origin}/emulator/v1/${documents}`, {
    method: "DELETE", headers: headers("owner"),
  }), 200);
});

test("an administrator can still create a fresh draft; other clients cannot", async () => {
  await expectStatus(await commit(admin, [draftWrite("fresh-draft")]), 200);
  for (const [auth, eventId] of [[attendee, "attendee-draft"], [null, "signed-out-draft"]]) {
    await expectStatus(await commit(auth, [draftWrite(eventId)]), 403);
  }
});

test("deleting and deleted event IDs cannot be recreated through direct admin writes", async () => {
  for (const status of ["deleting", "deleted"]) {
    const eventId = `cannot-recreate-${status}`;
    await seedMarker(eventId, status);
    await expectStatus(await commit(admin, [draftWrite(eventId)]), 403);
    await expectStatus(await fetch(`${base}/quizEvents/${eventId}`, { headers: headers("owner") }), 404);
  }
});

test("clients cannot create, alter, or delete deletion markers, including atomic recreation", async () => {
  const eventId = "protected-marker";
  await seedMarker(eventId, "deleted");
  for (const auth of [admin, attendee, null]) {
    for (const markerId of ["new-marker", eventId]) {
      await expectStatus(await fetch(`${base}/quizEventDeletions/${markerId}`, {
        method: "PATCH", headers: headers(auth),
        body: JSON.stringify({ fields: { status: { stringValue: "changed" } } }),
      }), 403);
    }
    await expectStatus(await fetch(`${base}/quizEventDeletions/${eventId}`, {
      method: "DELETE", headers: headers(auth),
    }), 403);
  }
  await expectStatus(await commit(admin, [
    { delete: `${documents}/quizEventDeletions/${eventId}` },
    draftWrite(eventId),
  ]), 403);
  const marker = await fetch(`${base}/quizEventDeletions/${eventId}`, { headers: headers("owner") });
  assert.equal(marker.status, 200);
  assert.equal((await marker.json()).fields.status.stringValue, "deleted");
  await expectStatus(await fetch(`${base}/quizEvents/${eventId}`, { headers: headers("owner") }), 404);
});

test("direct event deletion remains forbidden, including for administrators", async () => {
  const eventId = "must-delete-through-callable";
  await expectStatus(await commit(admin, [draftWrite(eventId)]), 200);
  for (const auth of [admin, attendee, null]) {
    await expectStatus(await fetch(`${base}/quizEvents/${eventId}`, {
      method: "DELETE", headers: headers(auth),
    }), 403);
  }
  await expectStatus(await fetch(`${base}/quizEvents/${eventId}`, { headers: headers("owner") }), 200);
});
