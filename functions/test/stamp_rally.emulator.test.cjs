const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { after, before, test } = require("node:test");
const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

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
const app = initializeApp({ projectId }, `stamp-rally-test-${randomUUID()}`);
const auth = getAuth(app);
const db = getFirestore(app);
const documentsPath = `projects/${projectId}/databases/(default)/documents`;
const documentsUrl = `http://${firestoreHost}/v1/${documentsPath}`;
const prefix = `stamp-test-${randomUUID().slice(0, 8)}`;
const sponsorIds = [`${prefix}-a`, `${prefix}-b`];
const users = [];
let originalSettings;
let settingsRead = false;
let admin;
let attendee;
let stranger;
let anonymous;

async function createUser(label, domain = "example.test") {
  const password = randomUUID();
  const user = await auth.createUser({
    uid: `${prefix}-${label}`, email: `${prefix}-${label}@${domain}`, emailVerified: true, password,
  });
  users.push(user.uid);
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-test-key`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: user.email, password, returnSecureToken: true }),
  });
  assert.equal(response.status, 200, `Emulator sign-in failed for ${label}`);
  return { uid: user.uid, token: (await response.json()).idToken };
}

function headers(user) {
  return { "Content-Type": "application/json", ...(user ? { Authorization: `Bearer ${user.token}` } : {}) };
}

async function call(name, user, data) {
  const response = await fetch(`http://${functionsHost}/${projectId}/asia-northeast1/${name}`, {
    method: "POST", headers: headers(user), body: JSON.stringify({ data }),
  });
  return response.json();
}

async function expectCallError(name, user, data, status) {
  const response = await call(name, user, data);
  assert.equal(response.error?.status, status, `Unexpected callable result: ${JSON.stringify(response)}`);
}

const read = (path, user) => fetch(`${documentsUrl}/${path}`, { headers: headers(user) });
const remove = (path, user) => fetch(`${documentsUrl}/${path}`, { method: "DELETE", headers: headers(user) });

/** Writes through the client API; `serverTime` sets that field to the request time. */
function write(user, path, fields, serverTime) {
  return fetch(`${documentsUrl}:commit`, {
    method: "POST",
    headers: headers(user),
    body: JSON.stringify({ writes: [{
      update: { name: `${documentsPath}/${path}`, fields },
      ...(serverTime ? { updateTransforms: [{ fieldPath: serverTime, setToServerValue: "REQUEST_TIME" }] } : {}),
    }] }),
  });
}

const ints = (...values) => ({ arrayValue: { values: values.map((value) => ({ integerValue: String(value) })) } });
const settings = (checkpoints, extra = {}) => ({ checkpoints, isOpen: { booleanValue: true }, ...extra });

before(async () => {
  originalSettings = (await db.doc("stampRallySettings/current").get()).data();
  settingsRead = true;
  [admin, attendee, stranger] = await Promise.all([
    createUser("admin", "flutterkaigi.jp"), createUser("attendee"), createUser("stranger"),
  ]);
  await db.doc(`admins/${admin.uid}`).set({});
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=local-test-key`, {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ returnSecureToken: true }),
  });
  const body = await response.json();
  anonymous = { uid: body.localId, token: body.idToken };
  users.push(anonymous.uid);
});

after(async () => {
  const batch = db.batch();
  for (const uid of users) {
    batch.delete(db.doc(`admins/${uid}`));
    batch.delete(db.doc(`stampRallyCards/${uid}`));
  }
  for (const id of [...sponsorIds, `${prefix}-client`]) batch.delete(db.doc(`stampRallySponsors/${id}`));
  if (settingsRead) {
    if (originalSettings) batch.set(db.doc("stampRallySettings/current"), originalSettings);
    else batch.delete(db.doc("stampRallySettings/current"));
  }
  await batch.commit();
  await Promise.all(users.map((uid) => auth.deleteUser(uid).catch((error) => {
    if (error.code !== "auth/user-not-found") throw error;
  })));
  await deleteApp(app);
});

test("Stamp rally callables, transactions, Auth cleanup, and Firestore security", async (t) => {
  let codes;

  await t.test("targets and settings are public; only admins write them with valid content", async () => {
    const sponsorPath = `stampRallySponsors/${prefix}-client`;
    for (const user of [attendee, anonymous, null]) {
      assert.equal((await write(user, sponsorPath, {}, "createdAt")).status, 403);
      assert.equal((await write(user, "stampRallySettings/current", settings(ints(1, 2)), "updatedAt")).status, 403);
    }
    assert.equal((await write(admin, sponsorPath, { createdAt: { timestampValue: "2026-01-01T00:00:00Z" } })).status, 403);
    assert.equal((await write(admin, sponsorPath, { extra: { booleanValue: true } }, "createdAt")).status, 403);
    assert.equal((await write(admin, sponsorPath, {}, "createdAt")).status, 200);
    assert.equal((await write(admin, sponsorPath, {}, "createdAt")).status, 403, "targets are not updated in place");
    for (const user of [null, anonymous, attendee]) assert.equal((await remove(sponsorPath, user)).status, 403);
    assert.equal((await remove(sponsorPath, admin)).status, 200);

    for (const invalid of [
      settings(ints()), settings(ints(1, 2, 3, 4, 5, 6)), settings(ints(2, 2)), settings(ints(3, 1)),
      settings(ints(0, 1)), settings({ arrayValue: { values: [{ stringValue: "7" }] } }),
      settings(ints(7), { isOpen: { stringValue: "true" } }), settings(ints(7), { extra: { booleanValue: true } }),
    ]) {
      assert.equal((await write(admin, "stampRallySettings/current", invalid, "updatedAt")).status, 403);
    }
    assert.equal((await write(admin, "stampRallySettings/current", settings(ints(7)))).status, 403, "updatedAt is server time");
    assert.equal((await write(admin, "stampRallySettings/other", settings(ints(7)), "updatedAt")).status, 403);
    assert.equal((await write(admin, "stampRallySettings/current", settings(ints(1, 2, 3, 4, 5)), "updatedAt")).status, 200);
    assert.equal((await remove("stampRallySettings/current", admin)).status, 403);

    for (const id of sponsorIds) await db.doc(`stampRallySponsors/${id}`).set({ createdAt: Timestamp.now() });
    for (const user of [null, anonymous, attendee]) {
      assert.equal((await read("stampRallySettings/current", user)).status, 200);
      assert.equal((await read(`stampRallySponsors/${sponsorIds[0]}`, user)).status, 200);
      assert.equal((await read("stampRallySponsors", user)).status, 200);
    }
  });

  await t.test("only active admins receive QR tokens", async () => {
    await expectCallError("getStampRallyQrCodes", null, {}, "UNAUTHENTICATED");
    await expectCallError("getStampRallyQrCodes", anonymous, {}, "PERMISSION_DENIED");
    await expectCallError("getStampRallyQrCodes", attendee, {}, "PERMISSION_DENIED");
    codes = (await call("getStampRallyQrCodes", admin, {})).result;
    for (const id of sponsorIds) {
      assert.match(codes.sponsors.find((sponsor) => sponsor.sponsorId === id)?.token, /^[0-9a-f]{64}$/);
    }
    assert.match(codes.reward, /^[0-9a-f]{64}$/);
    assert.match(codes.thanksCard, /^[0-9a-f]{64}$/);
  });

  const token = (id) => codes.sponsors.find((sponsor) => sponsor.sponsorId === id).token;

  await t.test("scans reject signed-out, anonymous, malformed and unknown codes", async () => {
    await expectCallError("scanStampRallyCode", null, { token: codes.reward }, "UNAUTHENTICATED");
    await expectCallError("scanStampRallyCode", anonymous, { token: codes.reward }, "PERMISSION_DENIED");
    await expectCallError("scanStampRallyCode", attendee, { token: "not-a-token" }, "INVALID_ARGUMENT");
    await expectCallError("scanStampRallyCode", attendee, { token: "0".repeat(64) }, "NOT_FOUND");
  });

  await t.test("concurrent scans of one booth record a single stamp and closing stops new stamps", async () => {
    await db.doc("stampRallySettings/current").set({ checkpoints: [1, 2], isOpen: true, updatedAt: Timestamp.now() });
    const responses = await Promise.all(Array.from({ length: 4 }, () => call("scanStampRallyCode", attendee, { token: token(sponsorIds[0]) })));
    assert.equal(responses.filter((response) => response.result?.alreadyAcquired === false).length, 1,
      JSON.stringify(responses));
    assert.deepEqual(responses.find((response) => response.result?.alreadyAcquired === false).result.newCheckpoints, [1]);
    await db.doc("stampRallySettings/current").update({ isOpen: false });
    await expectCallError("scanStampRallyCode", attendee, { token: token(sponsorIds[1]) }, "FAILED_PRECONDITION");
    await db.doc("stampRallySettings/current").update({ isOpen: true });
    const second = await call("scanStampRallyCode", attendee, { token: token(sponsorIds[1]) });
    assert.equal(second.result.stampCount, 2);
    assert.deepEqual(second.result.newCheckpoints, [2]);
  });

  await t.test("concurrent reward scans redeem each checkpoint once; the thanks card is redeemed once", async () => {
    const rewards = await Promise.all(Array.from({ length: 4 }, () => call("scanStampRallyCode", attendee, { token: codes.reward })));
    const redeemed = rewards.flatMap((response) => response.result?.redeemedCheckpoints ?? []);
    assert.deepEqual(redeemed.sort(), [1, 2], JSON.stringify(rewards));
    const thanks = await Promise.all(Array.from({ length: 3 }, () => call("scanStampRallyCode", attendee, { token: codes.thanksCard })));
    assert.equal(thanks.filter((response) => response.result?.alreadyRedeemed === false).length, 1, JSON.stringify(thanks));
    assert.equal(new Set(thanks.map((response) => response.result.redeemedAt)).size, 1);
    const card = (await db.doc(`stampRallyCards/${attendee.uid}`).get()).data();
    assert.deepEqual(Object.keys(card.stamps).sort(), sponsorIds);
    assert.deepEqual(Object.keys(card.rewardsRedeemedAt).sort(), ["1", "2"]);
  });

  await t.test("cards are readable only by the owner and admins and never writable by clients", async () => {
    const path = `stampRallyCards/${attendee.uid}`;
    assert.equal((await read(path, attendee)).status, 200);
    assert.equal((await read(path, admin)).status, 200);
    for (const user of [null, anonymous, stranger]) assert.equal((await read(path, user)).status, 403);
    assert.equal((await read("stampRallyCards", attendee)).status, 403);
    for (const user of [attendee, admin, stranger]) {
      assert.equal((await write(user, `stampRallyCards/${user.uid}`, { stamps: { mapValue: { fields: {} } } }, "updatedAt")).status, 403);
      assert.equal((await remove(path, user)).status, 403);
    }
  });

  await t.test("deleting the Auth account removes the card", async () => {
    await auth.deleteUser(attendee.uid);
    const deadline = Date.now() + 20_000;
    while (Date.now() < deadline && (await db.doc(`stampRallyCards/${attendee.uid}`).get()).exists) {
      await new Promise((resolve) => setTimeout(resolve, 200));
    }
    assert.equal((await db.doc(`stampRallyCards/${attendee.uid}`).get()).exists, false);
  });
});
