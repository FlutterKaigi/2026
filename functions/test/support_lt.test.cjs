const assert = require("node:assert/strict");
const { test } = require("node:test");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");
const {
  issueSupportLtCodeForUser,
  registerSupportLtForUser,
} = require("../lib/support_lt_service.js");
const { deleteAuthUserData } = require("../lib/auth_user_data.js");

const NOW = 1_800_000_000_000;
const BUCKET = String(Math.floor(NOW / 600_000));
const FAILURE_KEY = `v4_${BUCKET}`;
const ADMIN = {
  uid: "admin",
  token: {
    email: "staff@flutterkaigi.jp",
    email_verified: true,
    firebase: { sign_in_provider: "google.com" },
  },
};
const USER = {
  uid: "attendee",
  token: { name: "Auth name", firebase: { sign_in_provider: "password" } },
};

// Stage writes until the callback returns, just as Firestore transactions do.
// A thrown rejection inside the callback must never persist failed attempts.
function fixture(entries = {}) {
  const documents = new Map(Object.entries(entries));
  const events = [];
  // Non-transactional merge writes support FieldValue.increment on one nested level.
  const merge = (path, data) => {
    const current = { ...(documents.get(path) ?? {}) };
    for (const [key, value] of Object.entries(data)) {
      if (value != null && typeof value === "object" && !("isEqual" in value)) {
        current[key] = { ...(current[key] ?? {}) };
        for (const [nested, nestedValue] of Object.entries(value)) {
          current[key][nested] = nestedValue.isEqual?.(FieldValue.increment(1))
            ? (current[key][nested] ?? 0) + 1
            : nestedValue;
        }
      } else {
        current[key] = value;
      }
    }
    documents.set(path, current);
  };
  const ref = (path) => ({
    path,
    get: async () => { events.push(`plain-read:${path}`); return snapshot(path); },
    set: async (data, options) => {
      events.push(`plain-write:${path}`);
      if (options?.merge) merge(path, data);
      else documents.set(path, data);
    },
  });
  const snapshot = (path) => ({
    exists: documents.has(path),
    data: () => documents.get(path),
  });
  const mutations = () => {
    const writes = [];
    return {
      writes,
      set: (reference, data, options) => writes.push(() => {
        if (options?.merge) merge(reference.path, data);
        else documents.set(reference.path, data);
      }),
      create: (reference, data) => {
        assert.equal(documents.has(reference.path), false);
        writes.push(() => documents.set(reference.path, data));
      },
      delete: (reference) => writes.push(() => documents.delete(reference.path)),
    };
  };
  const db = {
    doc: ref,
    collection: (path) => ({
      doc: (id) => ref(`${path}/${id}`),
      get: async () => ({
        docs: [...documents.keys()]
          .filter((key) => key.startsWith(`${path}/`) && key.split("/").length === path.split("/").length + 1)
          .map((key) => ({ id: key.split("/").at(-1), ...snapshot(key) })),
      }),
    }),
    runTransaction: async (callback) => {
      const writes = mutations();
      try {
        const result = await callback({
          ...writes,
          get: async (reference) => {
            assert.equal(writes.writes.length, 0, "Firestore reads must precede writes");
            events.push(`read:${reference.path}`);
            return snapshot(reference.path);
          },
        });
        writes.writes.forEach((apply) => apply());
        events.push("transaction-commit");
        return result;
      } catch (error) {
        events.push("transaction-abort");
        throw error;
      }
    },
    batch: () => {
      const writes = mutations();
      return { ...writes, commit: async () => {
        events.push("batch-commit");
        writes.writes.forEach((apply) => apply());
      } };
    },
  };
  return {
    documents,
    events,
    dependencies: {
      db, now: () => NOW, randomInt: () => 0,
      getUser: async (uid) => { events.push(`auth:${uid}`); return { disabled: false }; },
    },
  };
}

function liveSettings(overrides = {}) {
  return {
    code: "000000",
    issuedAt: Timestamp.fromMillis(NOW - 1000),
    issuedBy: ADMIN.uid,
    version: 4,
    ...overrides,
  };
}

async function rejectsCode(promise, code) {
  await assert.rejects(promise, (error) => error.code === code);
}

test("issuance requires authenticated, verified domain member listed as admin", async () => {
  const { dependencies } = fixture({ "admins/admin": {} });
  for (const auth of [undefined, null]) {
    await rejectsCode(issueSupportLtCodeForUser(auth, {}, dependencies), "unauthenticated");
  }
  for (const token of [
    {},
    { email: "staff@flutterkaigi.jp", email_verified: false },
    { email: "staff@flutterkaigi.jp.evil", email_verified: true },
    { email: "staff@example.com", email_verified: true },
    { ...ADMIN.token, firebase: { sign_in_provider: "anonymous" } },
  ]) {
    await rejectsCode(issueSupportLtCodeForUser({ uid: "admin", token }, {}, dependencies), "permission-denied");
  }
  await rejectsCode(
    issueSupportLtCodeForUser({ ...ADMIN, uid: "unlisted" }, {}, dependencies),
    "permission-denied",
  );
});

test("issuance validates input before writing", async () => {
  const { dependencies, documents } = fixture({ "admins/admin": {} });
  for (const data of [null, [], "rotate", { rotate: "true" }, { rotate: 1 }, { code: "123456" }]) {
    await rejectsCode(issueSupportLtCodeForUser(ADMIN, data, dependencies), "invalid-argument");
  }
  assert.equal(documents.has("supportLtSettings/current"), false);
});

test("issuance creates a six-digit code without an expiry", async () => {
  const { dependencies, documents } = fixture({ "admins/admin": {} });
  const result = await issueSupportLtCodeForUser(ADMIN, {}, dependencies);
  assert.deepEqual(result, { code: "000000", issuedAt: NOW });
  assert.deepEqual(Object.keys(documents.get("supportLtSettings/current")).sort(), ["code", "issuedAt", "issuedBy", "version"]);
  const stored = documents.get("supportLtSettings/current");
  assert.equal(stored.issuedBy, ADMIN.uid);
  assert.equal(stored.version, 1);
  assert.equal(stored.issuedAt.toMillis(), NOW);
});

test("current code is reused indefinitely and explicit rotation always changes even a zero random draw", async () => {
  const original = liveSettings({ issuedAt: Timestamp.fromMillis(NOW - 30 * 86_400_000) });
  const { dependencies, documents } = fixture({
    "admins/admin": {}, "supportLtSettings/current": original,
    "supportLtSettings/attempts": { counts: { [BUCKET]: 200 } },
  });
  const result = await issueSupportLtCodeForUser(ADMIN, { rotate: false }, dependencies);
  assert.deepEqual(result, { code: original.code, issuedAt: NOW - 30 * 86_400_000 });
  assert.equal(documents.get("supportLtSettings/current"), original);
  assert.equal(documents.has("supportLtSettings/attempts"), true);
  const rotated = await issueSupportLtCodeForUser(ADMIN, { rotate: true }, dependencies);
  assert.equal(rotated.code, "000001");
  assert.equal(documents.get("supportLtSettings/current").version, 5);
  assert.deepEqual(documents.get("supportLtSettings/attempts"), { resetCodeVersion: 5, counts: {} }, "rotation lifts the shared block");
  await rejectsCode(registerSupportLtForUser(USER, { code: original.code }, dependencies), "not-found");
  await registerSupportLtForUser(USER, { code: rotated.code }, dependencies);
});

test("rotation from a wrapped code stays inside the six-digit space", async () => {
  const { dependencies } = fixture({
    "admins/admin": {},
    "supportLtSettings/current": liveSettings({ code: "999999" }),
  });
  const result = await issueSupportLtCodeForUser(ADMIN, { rotate: true }, dependencies);
  assert.equal(result.code, "000000");
});

test("registration rejects unauthenticated and anonymous accounts before writes", async () => {
  const { dependencies, documents } = fixture();
  await rejectsCode(registerSupportLtForUser(undefined, { code: "000000" }, dependencies), "unauthenticated");
  await rejectsCode(registerSupportLtForUser({
    uid: "anon", token: { firebase: { sign_in_provider: "anonymous" } },
  }, { code: "000000" }, dependencies), "permission-denied");
  assert.equal(documents.size, 0);
});

test("registration validates and normalizes six ASCII digits", async () => {
  const { dependencies } = fixture({ "supportLtSettings/current": liveSettings() });
  for (const data of [null, [], {}, { code: 123456 }, { code: "12345" }, { code: "１２３４５６" }, { code: "000000", uid: "other" }]) {
    await rejectsCode(registerSupportLtForUser(USER, data, dependencies), "invalid-argument");
  }
  const result = await registerSupportLtForUser(USER, { code: " 000000\n" }, dependencies);
  assert.deepEqual(result, { registeredAt: NOW, alreadyRegistered: false });
});

test("registration snapshots the optional profile name with auth name and uid fallbacks", async () => {
  const cases = [
    [{ displayName: "Profile name" }, USER.token, "Profile name"],
    [{ displayName: "  " }, USER.token, "Auth name"],
    [{ displayName: 12 }, USER.token, "Auth name"],
    [undefined, USER.token, "Auth name"],
    [undefined, { email: "private@example.com", name: " " }, USER.uid],
    [undefined, { name: 12 }, USER.uid],
  ];
  for (const [profile, token, expectedName] of cases) {
    const entries = { "supportLtSettings/current": liveSettings() };
    if (profile) entries[`users/${USER.uid}`] = profile;
    const { dependencies, documents } = fixture(entries);
    await registerSupportLtForUser({ uid: USER.uid, token }, { code: "000000" }, dependencies);
    const result = documents.get(`supportLtRegistrations/${USER.uid}`);
    assert.deepEqual(Object.keys(result).sort(), ["codeVersion", "displayName", "registeredAt"]);
    assert.equal(result.displayName, expectedName);
    assert.equal(result.codeVersion, 4);
    assert.equal(result.registeredAt.toMillis(), NOW);
  }
});

test("registration is idempotent after rotation and preserves the original record", async () => {
  const registration = { displayName: "First name", registeredAt: Timestamp.fromMillis(NOW - 1000), codeVersion: 1 };
  const { dependencies, documents } = fixture({
    [`supportLtRegistrations/${USER.uid}`]: registration,
    [`supportLtRegistrationAttempts/${USER.uid}`]: { failCount: 10, blockedUntil: Timestamp.fromMillis(NOW + 600_000) },
  });
  const result = await registerSupportLtForUser(USER, { code: "999999" }, dependencies);
  assert.deepEqual(result, { registeredAt: NOW - 1000, alreadyRegistered: true });
  assert.equal(documents.get(`supportLtRegistrations/${USER.uid}`), registration);
});

test("missing and incorrect codes persist per-user and shared failed attempts before rejecting", async () => {
  for (const settings of [undefined, liveSettings({ code: "111111" })]) {
    const entries = settings ? { "supportLtSettings/current": settings } : {};
    const { dependencies, documents, events } = fixture(entries);
    await rejectsCode(registerSupportLtForUser(USER, { code: "000000" }, dependencies), "not-found");
    const attempts = documents.get(`supportLtRegistrationAttempts/${USER.uid}`);
    assert.equal(attempts.failCount, 1);
    assert.equal(attempts.windowStartedAt.toMillis(), NOW);
    assert.deepEqual(documents.get("supportLtSettings/attempts"), { counts: { [`v${settings?.version ?? 0}_${BUCKET}`]: 1 } });
    assert.equal(events.includes(`read:users/${USER.uid}`), false, "profile is not read for a failed guess");
    // The hot shared document never takes part in the transaction.
    assert.equal(events.includes("read:supportLtSettings/attempts"), false);
    assert.ok(events.indexOf("transaction-commit") < events.indexOf("plain-write:supportLtSettings/attempts"));
  }
});

test("shared failures across accounts block the code for everyone in the bucket until rotation", async () => {
  const { dependencies, documents } = fixture({
    "supportLtSettings/current": liveSettings(),
    "supportLtSettings/attempts": { counts: { [FAILURE_KEY]: 199, "v3_0": 5 } },
  });
  await rejectsCode(registerSupportLtForUser({ uid: "guesser", token: {} }, { code: "111111" }, dependencies), "not-found");
  assert.deepEqual(documents.get("supportLtSettings/attempts"), { counts: { [FAILURE_KEY]: 200, "v3_0": 5 } });
  await rejectsCode(registerSupportLtForUser(USER, { code: "000000" }, dependencies), "resource-exhausted");
  assert.equal(documents.has(`supportLtRegistrations/${USER.uid}`), false);
  assert.equal(documents.has(`supportLtRegistrationAttempts/${USER.uid}`), false, "a shared block records no per-user failure");
  assert.deepEqual(documents.get("supportLtSettings/attempts"), { counts: { [FAILURE_KEY]: 200, "v3_0": 5 } });
  // The next ten-minute bucket starts with a fresh budget.
  await registerSupportLtForUser(USER, { code: "000000" }, { ...dependencies, now: () => NOW + 600_000 });
});

test("shared-limit preflight rejects a stable current or legacy block without Auth or transaction locks", async () => {
  for (const counts of [{ [FAILURE_KEY]: 200 }, { [BUCKET]: 200 }]) {
    const { dependencies, events, documents } = fixture({
      "supportLtSettings/current": liveSettings(),
      "supportLtSettings/attempts": { counts },
    });
    await rejectsCode(registerSupportLtForUser(USER, { code: "000000" }, dependencies), "resource-exhausted");
    assert.equal(events.some((event) => event.startsWith("auth:")), false, "blocked traffic must not call Auth");
    assert.equal(events.some((event) => event.startsWith("read:")), false, "blocked traffic must not acquire transaction read locks");
    assert.equal(events.includes("transaction-commit"), false);
    assert.equal(documents.has(`supportLtRegistrationAttempts/${USER.uid}`), false);
  }
});

test("shared-limit preflight cannot reject a new code using a blocked previous generation", async () => {
  const { dependencies, documents } = fixture({
    "admins/admin": {},
    "supportLtSettings/current": liveSettings(),
    "supportLtSettings/attempts": { counts: { [FAILURE_KEY]: 200 } },
  });
  let rotate = true;
  const db = {
    ...dependencies.db,
    doc(path) {
      const reference = dependencies.db.doc(path);
      if (path !== "supportLtSettings/attempts") return reference;
      return {
        ...reference,
        async get() {
          if (rotate) {
            rotate = false;
            await issueSupportLtCodeForUser(ADMIN, { rotate: true }, dependencies);
            // Previous-generation increments can arrive after rotation. The
            // pending request's original settings read is now obsolete.
            await reference.set({ counts: { [FAILURE_KEY]: 200 } }, { merge: true });
          }
          return reference.get();
        },
      };
    },
  };
  const registered = await registerSupportLtForUser(USER, { code: "000001" }, { ...dependencies, db });
  assert.equal(registered.alreadyRegistered, false);
  assert.equal(documents.get(`supportLtRegistrations/${USER.uid}`).codeVersion, 5);
});

test("shared-limit preflight rechecks the budget when rotation occurs before the registration transaction", async () => {
  const { dependencies, documents } = fixture({ "supportLtSettings/current": liveSettings() });
  const db = {
    ...dependencies.db,
    async runTransaction(callback) {
      documents.set("supportLtSettings/current", liveSettings({ version: 5, code: "000001" }));
      documents.set("supportLtSettings/attempts", { resetCodeVersion: 5, counts: { [`v5_${BUCKET}`]: 200 } });
      return dependencies.db.runTransaction(callback);
    },
  };
  await rejectsCode(registerSupportLtForUser(USER, { code: "000001" }, { ...dependencies, db }), "resource-exhausted");
  assert.equal(documents.has(`supportLtRegistrations/${USER.uid}`), false);
  assert.equal(documents.has(`supportLtRegistrationAttempts/${USER.uid}`), false);
});

test("shared-limit preflight rechecks the budget after crossing a ten-minute bucket", async () => {
  const { dependencies, documents } = fixture({
    "supportLtSettings/current": liveSettings(),
    "supportLtSettings/attempts": { counts: { [`v4_${Number(BUCKET) + 1}`]: 200 } },
  });
  let now = NOW;
  const db = {
    ...dependencies.db,
    async runTransaction(callback) {
      now += 600_000;
      return dependencies.db.runTransaction(callback);
    },
  };
  await rejectsCode(registerSupportLtForUser(USER, { code: "000000" }, {
    ...dependencies, db, now: () => now,
  }), "resource-exhausted");
  assert.equal(documents.has(`supportLtRegistrations/${USER.uid}`), false);
});

function deferred() {
  let resolve;
  const promise = new Promise((complete) => { resolve = complete; });
  return { promise, resolve };
}

test("200 delayed failures for the previous code cannot consume the new code's budget", async () => {
  const { dependencies, documents } = fixture({
    "admins/admin": {},
    "supportLtSettings/current": liveSettings(),
  });
  const allWritesQueued = deferred();
  const releaseWrites = deferred();
  let queued = 0;
  const delayedDb = {
    ...dependencies.db,
    doc(path) {
      const reference = dependencies.db.doc(path);
      if (path !== "supportLtSettings/attempts") return reference;
      return {
        ...reference,
        async set(data, options) {
          queued += 1;
          if (queued === 200) allWritesQueued.resolve();
          await releaseWrites.promise;
          return reference.set(data, options);
        },
      };
    },
  };
  const pending = Array.from({ length: 200 }, (_, index) => rejectsCode(
    registerSupportLtForUser({ uid: `old-guesser-${index}`, token: {} }, { code: "111111" }, {
      ...dependencies, db: delayedDb,
    }), "not-found",
  ));
  let rotated;
  try {
    await allWritesQueued.promise;
    assert.equal(documents.has("supportLtSettings/attempts"), false);
    rotated = await issueSupportLtCodeForUser(ADMIN, { rotate: true }, dependencies);
  } finally {
    releaseWrites.resolve();
    await Promise.all(pending);
  }
  const registered = await registerSupportLtForUser(USER, { code: rotated.code }, dependencies);
  assert.equal(registered.alreadyRegistered, false);
  assert.deepEqual(documents.get("supportLtSettings/attempts"), {
    resetCodeVersion: 5, counts: { [FAILURE_KEY]: 200 },
  });

  // Every failure against the new code still counts, including guesses that
  // reuse the old code. No per-user limit masks this cross-account check.
  for (let index = 0; index < 200; index++) {
    await rejectsCode(registerSupportLtForUser({ uid: `new-guesser-${index}`, token: {} }, {
      code: "000000",
    }, dependencies), "not-found");
  }
  assert.equal(documents.get("supportLtSettings/attempts").counts[`v5_${BUCKET}`], 200);
  const blockedUser = { uid: "new-bystander", token: {} };
  await rejectsCode(registerSupportLtForUser(blockedUser, { code: rotated.code }, dependencies), "resource-exhausted");
  assert.equal(documents.has(`supportLtRegistrationAttempts/${blockedUser.uid}`), false);
  const recovered = await issueSupportLtCodeForUser(ADMIN, { rotate: true }, dependencies);
  assert.equal((await registerSupportLtForUser(blockedUser, { code: recovered.code }, dependencies)).alreadyRegistered, false);
});

test("a committed failure keeps its checked generation and time even if recording starts after rotation", async () => {
  const { dependencies, documents } = fixture({
    "admins/admin": {},
    "supportLtSettings/current": liveSettings(),
  });
  const committed = deferred();
  const releaseResult = deferred();
  let now = NOW;
  const pending = rejectsCode(registerSupportLtForUser(USER, { code: "111111" }, {
    ...dependencies,
    now: () => now,
    db: {
      ...dependencies.db,
      async runTransaction(callback) {
        const outcome = await dependencies.db.runTransaction(callback);
        committed.resolve();
        await releaseResult.promise;
        return outcome;
      },
    },
  }), "not-found");
  try {
    await committed.promise;
    now += 600_000;
    await issueSupportLtCodeForUser(ADMIN, { rotate: true }, { ...dependencies, now: () => now });
  } finally {
    releaseResult.resolve();
    await pending;
  }
  assert.deepEqual(documents.get("supportLtSettings/attempts"), {
    resetCodeVersion: 5, counts: { [FAILURE_KEY]: 1 },
  });
});

test("legacy failure budgets survive deployment until rotation and late legacy writes cannot restore them", async () => {
  const { dependencies, documents } = fixture({
    "admins/admin": {},
    "supportLtSettings/current": liveSettings(),
    "supportLtSettings/attempts": { counts: { [BUCKET]: 199 } },
  });
  await rejectsCode(registerSupportLtForUser({ uid: "guesser", token: {} }, { code: "111111" }, dependencies), "not-found");
  assert.deepEqual(documents.get("supportLtSettings/attempts"), { counts: { [BUCKET]: 199, [FAILURE_KEY]: 1 } });
  await rejectsCode(registerSupportLtForUser(USER, { code: "000000" }, dependencies), "resource-exhausted");
  const rotated = await issueSupportLtCodeForUser(ADMIN, { rotate: true }, dependencies);
  // An in-flight request running the previous deployment can still merge a
  // bucket-only increment after rotation. Its unscoped budget is obsolete.
  await dependencies.db.doc("supportLtSettings/attempts").set({ counts: { [BUCKET]: 200 } }, { merge: true });
  assert.equal((await registerSupportLtForUser(USER, { code: rotated.code }, dependencies)).alreadyRegistered, false);
});

test("a per-user lock from the tenth failure counts once toward the shared budget", async () => {
  const { dependencies, documents } = fixture({
    "supportLtSettings/current": liveSettings(),
    [`supportLtRegistrationAttempts/${USER.uid}`]: { failCount: 9, windowStartedAt: Timestamp.fromMillis(NOW - 1000) },
  });
  await rejectsCode(registerSupportLtForUser(USER, { code: "111111" }, dependencies), "resource-exhausted");
  await rejectsCode(registerSupportLtForUser(USER, { code: "111111" }, dependencies), "resource-exhausted");
  assert.deepEqual(documents.get("supportLtSettings/attempts"), { counts: { [FAILURE_KEY]: 1 } });
});

test("ten failures within ten minutes lock attempts and a valid code cannot bypass lock", async () => {
  const { dependencies, documents } = fixture({ "supportLtSettings/current": liveSettings() });
  for (let failure = 1; failure <= 10; failure++) {
    await rejectsCode(registerSupportLtForUser(USER, { code: "111111" }, dependencies), failure === 10 ? "resource-exhausted" : "not-found");
  }
  const attempts = documents.get(`supportLtRegistrationAttempts/${USER.uid}`);
  assert.equal(attempts.failCount, 10);
  assert.equal(attempts.blockedUntil.toMillis(), NOW + 600_000);
  await rejectsCode(registerSupportLtForUser(USER, { code: "000000" }, dependencies), "resource-exhausted");
  assert.equal(documents.get(`supportLtRegistrationAttempts/${USER.uid}`), attempts);
  assert.equal(documents.has(`supportLtRegistrations/${USER.uid}`), false);
});

test("expired lock and old failure window reset attempts, and success clears state", async () => {
  for (const attempts of [
    { failCount: 10, windowStartedAt: Timestamp.fromMillis(NOW - 1_000_000), blockedUntil: Timestamp.fromMillis(NOW) },
    { failCount: 9, windowStartedAt: Timestamp.fromMillis(NOW - 600_000) },
  ]) {
    const { dependencies, documents } = fixture({
      "supportLtSettings/current": liveSettings(),
      [`supportLtRegistrationAttempts/${USER.uid}`]: attempts,
    });
    await rejectsCode(registerSupportLtForUser(USER, { code: "111111" }, dependencies), "not-found");
    const reset = documents.get(`supportLtRegistrationAttempts/${USER.uid}`);
    assert.equal(reset.failCount, 1);
    assert.equal(reset.blockedUntil, undefined);
    await registerSupportLtForUser(USER, { code: "000000" }, dependencies);
    assert.equal(documents.has(`supportLtRegistrationAttempts/${USER.uid}`), false);
  }
});

test("account cleanup deletes all account-scoped mission data and attempts without requiring a profile", async () => {
  const { dependencies, documents } = fixture({
    [`supportLtRegistrations/${USER.uid}`]: { displayName: "Name" },
    [`supportLtRegistrationAttempts/${USER.uid}`]: { failCount: 2 },
    [`snsPostRegistrations/${USER.uid}`]: { companion: "staff" },
    [`exchangeCodeAttempts/${USER.uid}`]: { failCount: 1 },
    "supportLtRegistrations/other": { displayName: "Other" },
  });
  await deleteAuthUserData(USER.uid, dependencies.db);
  await deleteAuthUserData(USER.uid, dependencies.db);
  assert.deepEqual([...documents.keys()], ["supportLtRegistrations/other", `quizParticipation/${USER.uid}`]);
  assert.equal(documents.get(`quizParticipation/${USER.uid}`).accountDeleted, true);
});

test("account cleanup removes quiz account details while preserving the active roster and score", async () => {
  const privatePaths = ["participantAccounts", "entryClaims", "entryAttempts", "checkInAttempts"]
    .map((collection) => `quizEvents/half-1/${collection}/${USER.uid}`);
  const { dependencies, documents } = fixture({
    "quizEvents/half-1": { status: "inProgress" },
    [`quizParticipation/${USER.uid}`]: { eventId: "half-1" },
    [`quizEvents/half-1/participants/${USER.uid}`]: { displayName: "Player", teamId: "team" },
    "quizEvents/half-1/teams/team": { score: 20 },
    "quizEvents/half-1/participantAccounts/other": { email: "other@example.test" },
    ...Object.fromEntries(privatePaths.map((path) => [path, { email: "attendee@example.test" }])),
  });
  await deleteAuthUserData(USER.uid, dependencies.db);
  await deleteAuthUserData(USER.uid, dependencies.db);
  for (const path of privatePaths) assert.equal(documents.has(path), false);
  assert.equal(documents.get("quizEvents/half-1/teams/team").score, 20);
  assert.equal(documents.get(`quizEvents/half-1/participants/${USER.uid}`).teamId, "team");
  assert.equal(documents.has("quizEvents/half-1/participantAccounts/other"), true);
  assert.equal(documents.get(`quizParticipation/${USER.uid}`).accountDeleted, true);
  assert.equal(documents.get(`quizParticipation/${USER.uid}`).eventId, "half-1");
});

test("active Auth lookup holds the registration document read lock and precedes all outcomes", async () => {
  for (const existing of [undefined, { registeredAt: Timestamp.fromMillis(NOW), displayName: "Name", codeVersion: 1 }]) {
    const entries = { "supportLtSettings/current": liveSettings() };
    if (existing) entries[`supportLtRegistrations/${USER.uid}`] = existing;
    const { dependencies, events } = fixture(entries);
    await registerSupportLtForUser(USER, { code: "000000" }, dependencies);
    const transactional = events.filter((event) => !event.startsWith("plain-"));
    assert.deepEqual(transactional.slice(0, 2), [`read:supportLtRegistrations/${USER.uid}`, `auth:${USER.uid}`]);
  }
});

test("deleted accounts abort registration before writes and clean only after releasing transaction locks", async () => {
  const { dependencies, events, documents } = fixture({
    "supportLtSettings/current": liveSettings(),
    [`supportLtRegistrationAttempts/${USER.uid}`]: { failCount: 1 },
  });
  const getUser = async () => { throw Object.assign(new Error("Deleted"), { code: "auth/user-not-found" }); };
  await rejectsCode(registerSupportLtForUser(USER, { code: "000000" }, { ...dependencies, getUser }), "unauthenticated");
  assert.ok(events.indexOf("transaction-abort") < events.indexOf("batch-commit"));
  assert.equal(documents.has(`supportLtRegistrations/${USER.uid}`), false);
  assert.equal(documents.has(`supportLtRegistrationAttempts/${USER.uid}`), false);
});

test("disabled accounts are rejected but keep their registration for re-enabling", async () => {
  const registration = { displayName: "Name", registeredAt: Timestamp.fromMillis(NOW - 1000), codeVersion: 1 };
  const { dependencies, events, documents } = fixture({
    "supportLtSettings/current": liveSettings(),
    [`supportLtRegistrations/${USER.uid}`]: registration,
  });
  const getUser = async () => ({ disabled: true });
  await rejectsCode(registerSupportLtForUser(USER, { code: "000000" }, { ...dependencies, getUser }), "permission-denied");
  assert.equal(events.at(-1), "transaction-abort");
  assert.equal(events.includes("batch-commit"), false);
  assert.equal(documents.get(`supportLtRegistrations/${USER.uid}`), registration);
});

test("exhausted transaction retries surface as a retryable aborted error", async () => {
  const { dependencies, documents } = fixture({ "supportLtSettings/current": liveSettings() });
  const contended = Object.assign(new Error("10 ABORTED: Transaction lock timeout."), { code: 10 });
  const db = { ...dependencies.db, runTransaction: async () => { throw contended; } };
  await rejectsCode(registerSupportLtForUser(USER, { code: "000000" }, { ...dependencies, db }), "aborted");
  assert.equal(documents.has(`supportLtRegistrations/${USER.uid}`), false);
  assert.equal(documents.has("supportLtSettings/attempts"), false, "a contended call is not a failed guess");
});

test("transient Auth failure inside the transaction cannot commit registration or attempts", async () => {
  for (const code of ["000000", "111111"]) {
    const { dependencies, events, documents } = fixture({ "supportLtSettings/current": liveSettings() });
    const unavailable = new Error("Auth unavailable");
    await assert.rejects(registerSupportLtForUser(USER, { code }, {
      ...dependencies, getUser: async () => { throw unavailable; },
    }), (error) => error === unavailable);
    assert.equal(events.at(-1), "transaction-abort");
    assert.equal(documents.has(`supportLtRegistrations/${USER.uid}`), false);
    assert.equal(documents.has(`supportLtRegistrationAttempts/${USER.uid}`), false);
  }
});
