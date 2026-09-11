import { randomInt } from "node:crypto";
import { Firestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { assertAdmin } from "./admin_auth";
import { assertActiveSupportLtUser, InactiveSupportLtUserError, SupportLtGetUser } from "./support_lt_auth";

const CODE_SPACE = 1_000_000;
const ATTEMPT_WINDOW_MILLIS = 10 * 60 * 1000;
/** Failures one account may make within a window before it is blocked. */
const MAX_FAILURES_PER_USER = 10;
/**
 * Failures across all accounts within a window before the code itself is
 * blocked. Throwaway accounts cannot multiply the per-user allowance beyond
 * this; rotating the code lifts the block.
 */
const MAX_FAILURES_SHARED = 200;
const SETTINGS_PATH = "supportLtSettings/current";
const SHARED_ATTEMPTS_PATH = "supportLtSettings/attempts";

export interface SupportLtAuth {
  uid: string;
  token: {
    email?: string;
    email_verified?: boolean;
    name?: unknown;
    firebase?: { sign_in_provider?: string };
  };
}

interface Dependencies {
  db: Firestore;
  getUser: SupportLtGetUser;
  now?: () => number;
  randomInt?: (max: number) => number;
}

interface CodeSettings {
  code: string;
  issuedAt: Timestamp;
  issuedBy: string;
  version: number;
}

interface Registration {
  displayName: string;
  registeredAt: Timestamp;
  codeVersion: number;
}

interface Attempts {
  failCount: number;
  windowStartedAt: Timestamp;
  blockedUntil?: Timestamp;
}

export interface IssueSupportLtCodeResult {
  code: string;
  issuedAt: number;
}

export interface RegisterSupportLtResult {
  registeredAt: number;
  alreadyRegistered: boolean;
}

function requireUser(auth: SupportLtAuth | null | undefined): SupportLtAuth {
  if (auth == null) {
    throw new HttpsError("unauthenticated", "サインインが必要です。");
  }
  if (auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("permission-denied", "アカウントでサインインしてください。");
  }
  return auth;
}

function parseData(data: unknown, allowedKeys: string[]): Record<string, unknown> {
  if (data == null || typeof data !== "object" || Array.isArray(data)
    || Object.keys(data).some((key) => !allowedKeys.includes(key))) {
    throw new HttpsError("invalid-argument", "リクエストの形式が正しくありません。");
  }
  return data as Record<string, unknown>;
}

function codeResult(settings: CodeSettings): IssueSupportLtCodeResult {
  return { code: settings.code, issuedAt: settings.issuedAt.toMillis() };
}

/** Reuses the current shared code; a rotation replaces it in the same transaction. */
export async function issueSupportLtCodeForUser(
  auth: SupportLtAuth | null | undefined,
  data: unknown,
  dependencies: Dependencies,
): Promise<IssueSupportLtCodeResult> {
  const user = requireUser(auth);
  const input = parseData(data, ["rotate"]);
  if (input.rotate !== undefined && typeof input.rotate !== "boolean") {
    throw new HttpsError("invalid-argument", "rotate は真偽値で指定してください。");
  }
  const { db } = dependencies;
  await Promise.all([assertActiveSupportLtUser(user.uid, dependencies.getUser), assertAdmin(user, db)]);
  const ref = db.doc(SETTINGS_PATH);
  return db.runTransaction(async (tx) => {
    const previous = (await tx.get(ref)).data() as CodeSettings | undefined;
    if (previous && input.rotate !== true) {
      return codeResult(previous);
    }
    const now = (dependencies.now ?? Date.now)();
    // Sampling the remaining 999,999 values guarantees the old code cannot
    // survive a rotation.
    const draw = (dependencies.randomInt ?? randomInt)(previous ? CODE_SPACE - 1 : CODE_SPACE);
    const number = previous ? (Number(previous.code) + 1 + draw) % CODE_SPACE : draw;
    const settings: CodeSettings = {
      code: number.toString().padStart(6, "0"),
      issuedAt: Timestamp.fromMillis(now),
      issuedBy: user.uid,
      version: (previous?.version ?? 0) + 1,
    };
    tx.set(ref, settings);
    // A new code starts with a clean shared failure budget so staff can
    // recover from a brute-force block by rotating.
    tx.delete(db.doc(SHARED_ATTEMPTS_PATH));
    return codeResult(settings);
  });
}

function isBlocked(attempts: Attempts | undefined, now: number): boolean {
  return attempts?.blockedUntil != null && attempts.blockedUntil.toMillis() > now;
}

function nextFailure(previous: Attempts | undefined, now: number, maxFailures: number): Attempts {
  const reset = previous == null || previous.windowStartedAt.toMillis() <= now - ATTEMPT_WINDOW_MILLIS
    || (previous.blockedUntil != null && previous.blockedUntil.toMillis() <= now);
  const failCount = (reset ? 0 : previous.failCount) + 1;
  return {
    failCount,
    windowStartedAt: reset ? Timestamp.fromMillis(now) : previous.windowStartedAt,
    ...(failCount >= maxFailures ? { blockedUntil: Timestamp.fromMillis(now + ATTEMPT_WINDOW_MILLIS) } : {}),
  };
}

function nonEmptyName(value: unknown): string | undefined {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : undefined;
}

type RegistrationOutcome =
  | { kind: "registered"; result: RegisterSupportLtResult }
  | { kind: "blocked" }
  | { kind: "invalid-code" };

function attemptRegistration(
  user: SupportLtAuth,
  code: string,
  dependencies: Dependencies,
): Promise<RegistrationOutcome> {
  const { db } = dependencies;
  const registrationRef = db.doc(`supportLtRegistrations/${user.uid}`);
  const attemptsRef = db.doc(`supportLtRegistrationAttempts/${user.uid}`);
  const sharedAttemptsRef = db.doc(SHARED_ATTEMPTS_PATH);
  return db.runTransaction<RegistrationOutcome>(async (tx) => {
    const existing = (await tx.get(registrationRef)).data() as Registration | undefined;
    // In Standard/PESSIMISTIC Firestore, this read lock also blocks onDelete's
    // batch until commit/rollback. Check Auth while holding it so cleanup can
    // never finish before this transaction recreates a deleted user's entry.
    await assertActiveSupportLtUser(user.uid, dependencies.getUser);
    if (existing) {
      return { kind: "registered", result: { registeredAt: existing.registeredAt.toMillis(), alreadyRegistered: true } };
    }
    const [settingsSnapshot, attemptsSnapshot, sharedSnapshot] = await Promise.all([
      tx.get(db.doc(SETTINGS_PATH)), tx.get(attemptsRef), tx.get(sharedAttemptsRef),
    ]);
    const settings = settingsSnapshot.data() as CodeSettings | undefined;
    const attempts = attemptsSnapshot.data() as Attempts | undefined;
    const shared = sharedSnapshot.data() as Attempts | undefined;
    const now = (dependencies.now ?? Date.now)();
    if (isBlocked(attempts, now) || isBlocked(shared, now)) {
      return { kind: "blocked" };
    }
    if (settings == null || settings.code !== code) {
      const failure = nextFailure(attempts, now, MAX_FAILURES_PER_USER);
      const sharedFailure = nextFailure(shared, now, MAX_FAILURES_SHARED);
      tx.set(attemptsRef, failure);
      tx.set(sharedAttemptsRef, sharedFailure);
      return { kind: failure.blockedUntil || sharedFailure.blockedUntil ? "blocked" : "invalid-code" };
    }
    // The profile is only needed for the display name, so read it after the
    // code matched instead of paying for it on every failed guess.
    const profile = (await tx.get(db.doc(`users/${user.uid}`))).data();
    const registration: Registration = {
      displayName: nonEmptyName(profile?.displayName) ?? nonEmptyName(user.token.name) ?? user.uid,
      registeredAt: Timestamp.fromMillis(now),
      codeVersion: settings.version,
    };
    tx.create(registrationRef, registration);
    tx.delete(attemptsRef);
    return { kind: "registered", result: { registeredAt: now, alreadyRegistered: false } };
  });
}

/** The uid is the document id, making retries and simultaneous calls idempotent. */
export async function registerSupportLtForUser(
  auth: SupportLtAuth | null | undefined,
  data: unknown,
  dependencies: Dependencies,
): Promise<RegisterSupportLtResult> {
  const user = requireUser(auth);
  const input = parseData(data, ["code"]);
  if (typeof input.code !== "string" || !/^[0-9]{6}$/.test(input.code.trim())) {
    throw new HttpsError("invalid-argument", "6桁の数字を入力してください。");
  }
  const outcome = await attemptRegistration(user, input.code.trim(), dependencies).catch(async (error: unknown) => {
    // Only a deleted account loses its data: a disabled account may be
    // re-enabled and must keep its registration. A separate batch must run
    // after rollback, never under this transaction's registration read lock,
    // or it would wait on its own lock indefinitely.
    if (error instanceof InactiveSupportLtUserError && error.deleted) {
      await deleteSupportLtUserData(user.uid, dependencies.db);
    }
    throw error;
  });
  // Throw only after commit: throwing inside the transaction would discard
  // the failed-attempt update and leave the six-digit code open to guessing.
  if (outcome.kind === "blocked") {
    throw new HttpsError("resource-exhausted", "試行回数が多すぎます。10分ほど待ってからお試しください。");
  }
  if (outcome.kind === "invalid-code") {
    throw new HttpsError("not-found", "コードが正しくありません。運営に確認してください。");
  }
  return outcome.result;
}

/** Auth deletion also reaches attendees who never created a users/{uid} profile. */
export async function deleteSupportLtUserData(uid: string, db: Firestore): Promise<void> {
  const batch = db.batch();
  batch.delete(db.doc(`supportLtRegistrations/${uid}`));
  batch.delete(db.doc(`supportLtRegistrationAttempts/${uid}`));
  await batch.commit();
}
