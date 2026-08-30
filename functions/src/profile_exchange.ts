import * as crypto from "node:crypto";
import { DocumentReference, FieldValue, Timestamp } from "firebase-admin/firestore";
import { onDocumentCreated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { defaultFirestore } from "./firebase_admin";
import { FUNCTIONS_REGION, isEmulator } from "./environment";

const exchangeTokenSecret = defineSecret("EXCHANGE_TOKEN_SECRET");

const EXCHANGE_TOKEN_VERSION = "v1";
const EXCHANGE_TOKEN_TTL_SECONDS = 24 * 60 * 60;

/** Computes the HMAC-SHA256 signature (hex) for a `v1.<uid>.<exp>` payload. */
function signExchangeToken(uid: string, exp: number, secret: string): string {
  return crypto
    .createHmac("sha256", secret)
    .update(`${EXCHANGE_TOKEN_VERSION}.${uid}.${exp}`)
    .digest("hex");
}

/** Builds a `v1.<uid>.<exp>.<sig>` token for [uid], expiring at [exp] (unix seconds). */
export function buildExchangeToken(uid: string, exp: number, secret: string): string {
  return `${EXCHANGE_TOKEN_VERSION}.${uid}.${exp}.${signExchangeToken(uid, exp, secret)}`;
}

export interface ParsedExchangeToken {
  uid: string;
  exp: number;
}

/**
 * Verifies a token built by [buildExchangeToken], returning its claims when
 * the signature, version and expiry all check out, or `null` otherwise.
 *
 * `timingSafeEqual` requires equal-length buffers, so a length mismatch is
 * treated as an invalid signature rather than thrown.
 */
export function verifyExchangeToken(token: string, secret: string): ParsedExchangeToken | null {
  const parts = token.split(".");
  if (parts.length !== 4) {
    return null;
  }
  const [version, uid, expRaw, signature] = parts;
  if (version !== EXCHANGE_TOKEN_VERSION || uid.length === 0) {
    return null;
  }
  const exp = Number(expRaw);
  if (!Number.isInteger(exp)) {
    return null;
  }

  const expected = Buffer.from(signExchangeToken(uid, exp, secret), "hex");
  const actual = Buffer.from(signature, "hex");
  if (expected.length !== actual.length || !crypto.timingSafeEqual(expected, actual)) {
    return null;
  }
  if (exp < Math.floor(Date.now() / 1000)) {
    return null;
  }
  return { uid, exp };
}

export interface IssueExchangeTokenResult {
  token: string;
  expiresAt: number;
}

/** Reads the HMAC secret, failing loudly rather than signing with an empty key. */
function requireExchangeTokenSecret(): string {
  const secret = exchangeTokenSecret.value();
  if (secret.length === 0) {
    // defineSecret().value() returns "" (not a thrown error) when the secret
    // isn't configured, and an empty HMAC key is reproducible by anyone.
    logger.error("EXCHANGE_TOKEN_SECRET is not configured");
    throw new HttpsError("internal", "プロフィール交換用のトークンを発行できませんでした。");
  }
  return secret;
}

/**
 * Issues a signed, time-limited token for the caller's own uid so the app can
 * embed it in a QR code without exposing the uid directly. The client caches
 * the token and can keep displaying it offline until [expiresAt].
 */
export const issueExchangeToken = onCall(
  {
    region: FUNCTIONS_REGION,
    enforceAppCheck: !isEmulator,
    secrets: [exchangeTokenSecret],
  },
  (request): IssueExchangeTokenResult => {
    if (request.auth == null) {
      throw new HttpsError("unauthenticated", "サインインが必要です。");
    }
    const secret = requireExchangeTokenSecret();
    const expiresAt = Math.floor(Date.now() / 1000) + EXCHANGE_TOKEN_TTL_SECONDS;
    return {
      token: buildExchangeToken(request.auth.uid, expiresAt, secret),
      expiresAt,
    };
  },
);

/** `counters/{counterId}` document id tallying every completed exchange pair. */
const PROFILE_EXCHANGES_COUNTER_ID = "profileExchanges";

/**
 * Mirrors a verified `scan` exchange to the other attendee, increments the
 * `counters/profileExchanges` aggregate, and clears the token from the
 * scanning attendee's document.
 *
 * `origin === 'mirror'` documents are created by this same trigger, so they
 * are skipped to avoid mirroring a mirror (and are therefore never counted,
 * which keeps the counter equal to the number of exchanged pairs). An
 * invalid/expired/tampered token, or a token whose uid does not match the
 * scanned attendee, is treated as a forged exchange and the created document
 * is deleted outright.
 */
export const onProfileExchangeCreated = onDocumentCreated(
  {
    document: "users/{uid}/exchanges/{otherUid}",
    region: FUNCTIONS_REGION,
    secrets: [exchangeTokenSecret],
    // Idempotent (see the mirror-existence check below), so a retried
    // delivery after a transient failure is safe.
    retry: true,
  },
  async (event) => {
    const snapshot = event.data;
    if (snapshot == null) {
      return;
    }
    const data = snapshot.data();
    if (data.origin === "mirror") {
      return;
    }

    const { uid, otherUid } = event.params;
    const secret = exchangeTokenSecret.value();
    // An empty secret (unconfigured — see issueExchangeToken) can never
    // produce a token that verifies correctly, but treat it as an explicit
    // configuration failure rather than letting every token fail silently.
    if (secret.length === 0) {
      logger.error("EXCHANGE_TOKEN_SECRET is not configured; rejecting the exchange", { uid, otherUid });
      await snapshot.ref.delete();
      return;
    }
    const parsed = verifyExchangeToken(typeof data.token === "string" ? data.token : "", secret);
    if (parsed == null || parsed.uid !== otherUid) {
      logger.warn("Rejected an invalid profile exchange token", { uid, otherUid });
      await snapshot.ref.delete();
      return;
    }

    const db = defaultFirestore();
    const mirrorRef = db.collection("users").doc(otherUid).collection("exchanges").doc(uid);
    const counterRef = db.collection("counters").doc(PROFILE_EXCHANGES_COUNTER_ID);
    // Mirror creation and the counter increment commit atomically, and the
    // mirror's existence gates both: onDocumentCreated retries at least once,
    // so a retry that finds the mirror already present (from this trigger's
    // own earlier attempt, or a concurrent real scan from the other attendee
    // verifying their side at the same moment) must skip both writes rather
    // than double-mirror or double-count.
    await db.runTransaction(async (tx) => {
      const mirrorSnapshot = await tx.get(mirrorRef);
      if (mirrorSnapshot.exists) {
        return;
      }
      tx.create(mirrorRef, {
        createdAt: FieldValue.serverTimestamp(),
        origin: "mirror",
        token: null,
        note: null,
      });
      tx.set(counterRef, { count: FieldValue.increment(1) }, { merge: true });
    });

    await snapshot.ref.update({ token: null });
  },
);

const EXCHANGE_CODE_LENGTH = 6;
const EXCHANGE_CODE_TTL_MILLIS = 5 * 60 * 1000;
const EXCHANGE_CODE_ISSUE_ATTEMPTS = 10;
const MAX_REDEEM_FAILURES = 10;
const REDEEM_BLOCK_DURATION_MILLIS = 10 * 60 * 1000;

/** A cryptographically random zero-padded 6-digit code. */
function randomExchangeCode(): string {
  return crypto.randomInt(0, 10 ** EXCHANGE_CODE_LENGTH).toString().padStart(EXCHANGE_CODE_LENGTH, "0");
}

export interface IssueExchangeCodeResult {
  code: string;
  expiresAt: number;
}

/**
 * Issues a short-lived 6-digit code for the caller's own uid — the fallback
 * exchange path for camera-denied or otherwise QR-incapable devices.
 *
 * The code itself is too short to be a signed token (a forged 6-digit value
 * is trivially guessable), so unlike [issueExchangeToken] it is looked up
 * server-side: [redeemExchangeCode] reads `exchangeCodes/{code}` to find the
 * issuing uid, then hands back a normal signed exchange token so the create()
 * path stays the same for both QR and code exchanges.
 */
export const issueExchangeCode = onCall(
  { enforceAppCheck: !isEmulator },
  async (request): Promise<IssueExchangeCodeResult> => {
    if (request.auth == null) {
      throw new HttpsError("unauthenticated", "サインインが必要です。");
    }
    const uid = request.auth.uid;
    const db = defaultFirestore();
    const codesRef = db.collection("exchangeCodes");

    // A fresh code invalidates any code this uid issued earlier, so an old
    // code copied down by mistake can't still be redeemed.
    const previous = await codesRef.where("uid", "==", uid).get();
    if (!previous.empty) {
      const batch = db.batch();
      for (const doc of previous.docs) {
        batch.delete(doc.ref);
      }
      await batch.commit();
    }

    const expiresAtMillis = Date.now() + EXCHANGE_CODE_TTL_MILLIS;
    for (let attempt = 0; attempt < EXCHANGE_CODE_ISSUE_ATTEMPTS; attempt++) {
      const code = randomExchangeCode();
      try {
        await codesRef.doc(code).create({
          uid,
          expiresAt: Timestamp.fromMillis(expiresAtMillis),
        });
        return { code, expiresAt: Math.floor(expiresAtMillis / 1000) };
      } catch (error) {
        if (!isAlreadyExists(error)) {
          throw error;
        }
        // Collided with another attendee's live code; try another value.
      }
    }
    throw new HttpsError("resource-exhausted", "コードを発行できませんでした。もう一度お試しください。");
  },
);

function isAlreadyExists(error: unknown): boolean {
  // google-gax status code 6 = ALREADY_EXISTS.
  return typeof error === "object" && error != null && (error as { code?: number }).code === 6;
}

interface RedeemAttempts {
  failCount?: number;
  blockedUntil?: Timestamp;
}

/**
 * Computes the [RedeemAttempts] update for one failed [redeemExchangeCode]
 * call, blocking further attempts once [MAX_REDEEM_FAILURES] is reached
 * within a rolling window.
 *
 * A `blockedUntil` that has already passed resets the count, so a legitimate
 * user isn't re-blocked by attempts made before their previous block expired.
 * Pure (no I/O) so the caller can apply it inside a transaction alongside the
 * read it was computed from.
 */
function nextFailedRedeemAttempts(current: RedeemAttempts | undefined): RedeemAttempts {
  const blockExpired = current?.blockedUntil != null && current.blockedUntil.toMillis() <= Date.now();
  const failCount = (blockExpired ? 0 : (current?.failCount ?? 0)) + 1;
  const update: RedeemAttempts = { failCount };
  if (failCount >= MAX_REDEEM_FAILURES) {
    update.blockedUntil = Timestamp.fromMillis(Date.now() + REDEEM_BLOCK_DURATION_MILLIS);
  }
  return update;
}

type RedeemOutcome =
  | { kind: "blocked" }
  | { kind: "not-found" }
  | { kind: "expired" }
  | { kind: "self" }
  | { kind: "success"; otherUid: string };

/**
 * Redeems a 6-digit code issued by [issueExchangeCode], returning a signed
 * exchange token for the issuing attendee's uid in the same shape as
 * [issueExchangeToken] — so the client feeds it into the same
 * `users/{me}/exchanges/{otherUid}` create() path used for QR scans, rather
 * than the code flow having its own way to create an exchange.
 */
export const redeemExchangeCode = onCall(
  {
    enforceAppCheck: !isEmulator,
    secrets: [exchangeTokenSecret],
  },
  async (request): Promise<IssueExchangeTokenResult> => {
    if (request.auth == null) {
      throw new HttpsError("unauthenticated", "サインインが必要です。");
    }
    const uid = request.auth.uid;
    const rawCode = request.data?.code;
    if (typeof rawCode !== "string" || !/^\d{6}$/.test(rawCode.trim())) {
      throw new HttpsError("invalid-argument", "6桁の数字を入力してください。");
    }
    const code = rawCode.trim();

    const db = defaultFirestore();
    const attemptsRef = db.collection("exchangeCodeAttempts").doc(uid);
    const codeRef = db.collection("exchangeCodes").doc(code);

    // The block check, the failure-count increment, and the code's
    // read-then-delete all happen inside one transaction so a burst of
    // concurrent calls from the same uid can't all read "not blocked yet" /
    // "code still exists" before any of them commits: Firestore serializes
    // (via retry-on-conflict) transactions that touch the same documents,
    // so only one call in a burst can win a given code, and the Nth failure
    // that crosses MAX_REDEEM_FAILURES is guaranteed to be observed by every
    // later call in the same burst rather than racing past it.
    const outcome = await db.runTransaction<RedeemOutcome>(async (tx) => {
      const [attemptsSnapshot, codeSnapshot] = await Promise.all([tx.get(attemptsRef), tx.get(codeRef)]);
      const attemptsData = attemptsSnapshot.data() as RedeemAttempts | undefined;
      if (attemptsData?.blockedUntil != null && attemptsData.blockedUntil.toMillis() > Date.now()) {
        return { kind: "blocked" };
      }

      if (!codeSnapshot.exists) {
        tx.set(attemptsRef, nextFailedRedeemAttempts(attemptsData), { merge: true });
        return { kind: "not-found" };
      }
      const codeData = codeSnapshot.data()!;
      const otherUid = codeData.uid as string;
      const expiresAt = codeData.expiresAt as Timestamp;
      if (expiresAt.toMillis() < Date.now()) {
        tx.delete(codeRef);
        tx.set(attemptsRef, nextFailedRedeemAttempts(attemptsData), { merge: true });
        return { kind: "expired" };
      }
      if (otherUid === uid) {
        // Not a brute-force signal (the caller can only ever produce their
        // own uid's code by knowing it already), so this doesn't count as a
        // failure, and the code stays redeemable for its actual owner.
        return { kind: "self" };
      }

      // Consumed: a code is redeemable once, same as a QR scan's exchange
      // create() failing with ALREADY_EXISTS on a second attempt. Reading
      // and deleting inside the same transaction closes the window where two
      // concurrent redeems could both observe the code as existing.
      tx.delete(codeRef);
      tx.delete(attemptsRef);
      return { kind: "success", otherUid };
    });

    switch (outcome.kind) {
      case "blocked":
        throw new HttpsError("resource-exhausted", "試行回数が多すぎます。しばらくしてからもう一度お試しください。");
      case "not-found":
        throw new HttpsError("not-found", "コードが見つかりません。入力内容を確認してください。");
      case "expired":
        throw new HttpsError("not-found", "コードの有効期限が切れています。");
      case "self":
        throw new HttpsError("failed-precondition", "自分のコードは入力できません。");
      case "success": {
        const secret = requireExchangeTokenSecret();
        const expiresAtSeconds = Math.floor(Date.now() / 1000) + EXCHANGE_TOKEN_TTL_SECONDS;
        return {
          token: buildExchangeToken(outcome.otherUid, expiresAtSeconds, secret),
          expiresAt: expiresAtSeconds,
        };
      }
    }
  },
);

/** Firestore batched-write limit, matching `index.ts`'s `BATCH_CHUNK_SIZE`. */
const DELETE_CHUNK_SIZE = 400;

async function deleteInChunks(refs: DocumentReference[]): Promise<void> {
  const db = defaultFirestore();
  for (let i = 0; i < refs.length; i += DELETE_CHUNK_SIZE) {
    const batch = db.batch();
    for (const ref of refs.slice(i, i + DELETE_CHUNK_SIZE)) {
      batch.delete(ref);
    }
    await batch.commit();
  }
}

/**
 * Cleans up profile-exchange data left behind when `users/{uid}` is deleted
 * (see `AuthRepository.deleteAccount`'s `beforeDelete` hook, which removes
 * that document as part of account deletion).
 *
 * Removes the deleted uid's own `exchanges` subcollection and, for every
 * attendee it references, the mirror at `users/{otherUid}/exchanges/{uid}`.
 * Every id in the deleted uid's own subcollection has such a mirror by
 * construction (`onProfileExchangeCreated` creates one for both `scan` and
 * the resulting `mirror` side), so no `collectionGroup` scan is needed to
 * find them.
 *
 * Batched deletes handle a large exchange history without exceeding the
 * per-batch write limit. Re-running against an already-cleaned uid finds no
 * documents and deletes nothing, so an at-least-once retry can't loop or
 * fail.
 */
export const onProfileExchangeOwnerDeleted = onDocumentDeleted(
  {
    document: "users/{uid}",
    // Re-running against an already-cleaned uid deletes nothing (see above),
    // so a retried delivery after a transient failure is safe.
    retry: true,
  },
  async (event) => {
    const { uid } = event.params;
    const db = defaultFirestore();
    const ownExchanges = db.collection("users").doc(uid).collection("exchanges");
    const snapshot = await ownExchanges.get();

    const refs = [
      ...snapshot.docs.map((doc) => doc.ref),
      ...snapshot.docs.map((doc) => db.collection("users").doc(doc.id).collection("exchanges").doc(uid)),
    ];
    await deleteInChunks(refs);
  },
);
