import * as crypto from "node:crypto";
import { FieldValue } from "firebase-admin/firestore";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { defaultFirestore } from "./firebase_admin";
import { isEmulator } from "./environment";

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

/**
 * Issues a signed, time-limited token for the caller's own uid so the app can
 * embed it in a QR code without exposing the uid directly. The client caches
 * the token and can keep displaying it offline until [expiresAt].
 */
export const issueExchangeToken = onCall(
  {
    enforceAppCheck: !isEmulator,
    secrets: [exchangeTokenSecret],
  },
  (request): IssueExchangeTokenResult => {
    if (request.auth == null) {
      throw new HttpsError("unauthenticated", "サインインが必要です。");
    }
    const secret = exchangeTokenSecret.value();
    if (secret.length === 0) {
      // defineSecret().value() returns "" (not a thrown error) when the
      // secret isn't configured, and an empty HMAC key is reproducible by
      // anyone — so this must fail loudly rather than sign with it.
      logger.error("EXCHANGE_TOKEN_SECRET is not configured");
      throw new HttpsError("internal", "プロフィール交換用のトークンを発行できませんでした。");
    }
    const expiresAt = Math.floor(Date.now() / 1000) + EXCHANGE_TOKEN_TTL_SECONDS;
    return {
      token: buildExchangeToken(request.auth.uid, expiresAt, secret),
      expiresAt,
    };
  },
);

/**
 * Mirrors a verified `scan` exchange to the other attendee and clears the
 * token from the scanning attendee's document.
 *
 * `origin === 'mirror'` documents are created by this same trigger, so they
 * are skipped to avoid mirroring a mirror. An invalid/expired/tampered token,
 * or a token whose uid does not match the scanned attendee, is treated as a
 * forged exchange and the created document is deleted outright.
 */
export const onProfileExchangeCreated = onDocumentCreated(
  {
    document: "users/{uid}/exchanges/{otherUid}",
    secrets: [exchangeTokenSecret],
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
    try {
      // create() (not get-then-set) so a concurrent real scan from the other
      // attendee — who may be verifying their own mirror of this exchange at
      // the same moment — can never have its own `origin: 'scan'` document
      // overwritten by this mirror; the loser just hits ALREADY_EXISTS below.
      await mirrorRef.create({
        createdAt: FieldValue.serverTimestamp(),
        origin: "mirror",
        token: null,
        note: null,
      });
    } catch (error) {
      const alreadyExists = typeof error === "object" && error != null && (error as { code?: number }).code === 6;
      if (!alreadyExists) {
        throw error;
      }
    }

    await snapshot.ref.update({ token: null });
  },
);
