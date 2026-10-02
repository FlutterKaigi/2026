import { createHmac, timingSafeEqual } from "node:crypto";
import { Firestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { assertAdmin } from "./admin_auth";
import { deleteAuthUserData } from "./auth_user_data";
import { assertActiveSupportLtUser, InactiveSupportLtUserError, SupportLtGetUser } from "./support_lt_auth";
import { isFirestoreAborted, parseData, requireUser, SupportLtAuth } from "./support_lt_service";

export const DEFAULT_CHECKPOINTS = [7, 14, 22];
const SETTINGS_PATH = "stampRallySettings/current";
const SPONSORS_COLLECTION = "stampRallySponsors";
const REWARD_PURPOSE = "reward.v1";
const THANKS_CARD_PURPOSE = "thanks.v1";
const TOKEN_PATTERN = /^[0-9a-f]{64}$/;

interface Dependencies {
  db: Firestore;
  getUser: SupportLtGetUser;
  secret: string;
  now?: () => number;
}

interface Card {
  stamps?: Record<string, Timestamp>;
  rewardsRedeemedAt?: Record<string, Timestamp>;
  thanksCardRedeemedAt?: Timestamp;
}

export type ScanStampRallyResult =
  | {
    kind: "stamp";
    sponsorId: string;
    alreadyAcquired: boolean;
    acquiredAt: number;
    stampCount: number;
    newCheckpoints: number[];
    checkpoints: number[];
  }
  | {
    kind: "reward";
    redeemedCheckpoints: number[];
    redeemedAt: number | null;
    stampCount: number;
    checkpoints: number[];
    rewardsRedeemedAt: Record<string, number>;
  }
  | { kind: "thanksCard"; alreadyRedeemed: boolean; redeemedAt: number };

export interface StampRallyQrCodes {
  sponsors: { sponsorId: string; token: string }[];
  reward: string;
  thanksCard: string;
}

/** Printed QR codes never expire, so the token is a fixed signature of its purpose. */
export function stampRallyToken(secret: string, purpose: string): string {
  return createHmac("sha256", secret).update(purpose).digest("hex");
}

function stampPurpose(sponsorId: string): string {
  return `stamp.v1.${sponsorId}`;
}

/** Both sides are validated 64-character hex strings, so the buffers have equal length. */
function matches(token: string, secret: string, purpose: string): boolean {
  return timingSafeEqual(Buffer.from(token, "hex"), Buffer.from(stampRallyToken(secret, purpose), "hex"));
}

function checkpointsOf(settings: Record<string, unknown> | undefined): number[] {
  const value = settings?.checkpoints;
  return Array.isArray(value) && value.length > 0 && value.every((entry) => Number.isInteger(entry) && entry > 0)
    ? value
    : DEFAULT_CHECKPOINTS;
}

/** Checkpoint numbers are 1-based, following the order of `checkpoints`. */
function achieved(checkpoints: number[], stampCount: number): number[] {
  return checkpoints.flatMap((required, index) => stampCount >= required ? [index + 1] : []);
}

function toMillis(map: Record<string, Timestamp>): Record<string, number> {
  return Object.fromEntries(Object.entries(map).map(([key, value]) => [key, value.toMillis()]));
}

function attemptScan(user: SupportLtAuth, token: string, dependencies: Dependencies): Promise<ScanStampRallyResult> {
  const { db, secret } = dependencies;
  const cardRef = db.doc(`stampRallyCards/${user.uid}`);
  return db.runTransaction(async (tx) => {
    const card = (await tx.get(cardRef)).data() as Card | undefined;
    // Same ordering as registerSupportLt: the card's read lock makes Auth
    // deletion cleanup wait, so a deleted account cannot recreate its card.
    await assertActiveSupportLtUser(user.uid, dependencies.getUser);
    const [settingsSnapshot, sponsorsSnapshot] = await Promise.all([
      tx.get(db.doc(SETTINGS_PATH)), tx.get(db.collection(SPONSORS_COLLECTION)),
    ]);
    const settings = settingsSnapshot.data();
    const checkpoints = checkpointsOf(settings);
    const stamps = card?.stamps ?? {};
    const stampCount = Object.keys(stamps).length;
    const now = Timestamp.fromMillis((dependencies.now ?? Date.now)());

    if (matches(token, secret, REWARD_PURPOSE)) {
      const redeemed = card?.rewardsRedeemedAt ?? {};
      const redeemable = achieved(checkpoints, stampCount).filter((number) => redeemed[String(number)] == null);
      const additions = Object.fromEntries(redeemable.map((number) => [String(number), now]));
      if (redeemable.length > 0) {
        tx.set(cardRef, { rewardsRedeemedAt: additions, updatedAt: now }, { merge: true });
      }
      return {
        kind: "reward",
        redeemedCheckpoints: redeemable,
        redeemedAt: redeemable.length > 0 ? now.toMillis() : null,
        stampCount,
        checkpoints,
        rewardsRedeemedAt: toMillis({ ...redeemed, ...additions }),
      };
    }

    if (matches(token, secret, THANKS_CARD_PURPOSE)) {
      if (card?.thanksCardRedeemedAt) {
        return { kind: "thanksCard", alreadyRedeemed: true, redeemedAt: card.thanksCardRedeemedAt.toMillis() };
      }
      tx.set(cardRef, { thanksCardRedeemedAt: now, updatedAt: now }, { merge: true });
      return { kind: "thanksCard", alreadyRedeemed: false, redeemedAt: now.toMillis() };
    }

    const sponsorId = sponsorsSnapshot.docs.map((document) => document.id)
      .find((id) => matches(token, secret, stampPurpose(id)));
    if (sponsorId == null) {
      throw new HttpsError("not-found", "このQRコードはスタンプラリーで利用できません。");
    }
    const existing = stamps[sponsorId];
    if (existing) {
      return {
        kind: "stamp", sponsorId, alreadyAcquired: true, acquiredAt: existing.toMillis(),
        stampCount, newCheckpoints: [], checkpoints,
      };
    }
    if (settings?.isOpen !== true) {
      throw new HttpsError("failed-precondition", "現在スタンプラリーは受け付けていません。");
    }
    tx.set(cardRef, { stamps: { [sponsorId]: now }, updatedAt: now }, { merge: true });
    const previouslyAchieved = new Set(achieved(checkpoints, stampCount));
    return {
      kind: "stamp", sponsorId, alreadyAcquired: false, acquiredAt: now.toMillis(),
      stampCount: stampCount + 1,
      newCheckpoints: achieved(checkpoints, stampCount + 1).filter((number) => !previouslyAchieved.has(number)),
      checkpoints,
    };
  });
}

/** Determines the code's purpose from its signature and records the outcome on the caller's card. */
export async function scanStampRallyCodeForUser(
  auth: SupportLtAuth | null | undefined,
  data: unknown,
  dependencies: Dependencies,
): Promise<ScanStampRallyResult> {
  const user = requireUser(auth);
  const input = parseData(data, ["token"]);
  if (typeof input.token !== "string" || !TOKEN_PATTERN.test(input.token)) {
    throw new HttpsError("invalid-argument", "QRコードの形式が正しくありません。");
  }
  return attemptScan(user, input.token, dependencies).catch(async (error: unknown) => {
    // Cleanup must run after rollback, never under the card's read lock.
    if (error instanceof InactiveSupportLtUserError && error.deleted) {
      await deleteAuthUserData(user.uid, dependencies.db);
    }
    if (isFirestoreAborted(error)) {
      throw new HttpsError("aborted", "混み合っています。少し待ってからもう一度お試しください。");
    }
    throw error;
  });
}

/** Tokens are returned without a domain; the dashboard pairs them with its own flavor's origin. */
export async function getStampRallyQrCodesForUser(
  auth: SupportLtAuth | null | undefined,
  data: unknown,
  dependencies: Dependencies,
): Promise<StampRallyQrCodes> {
  const user = requireUser(auth);
  if (data != null) parseData(data, []);
  const { db, secret } = dependencies;
  await Promise.all([assertActiveSupportLtUser(user.uid, dependencies.getUser), assertAdmin(user, db)]);
  const sponsorIds = (await db.collection(SPONSORS_COLLECTION).get()).docs.map((document) => document.id).sort();
  return {
    sponsors: sponsorIds.map((sponsorId) => ({ sponsorId, token: stampRallyToken(secret, stampPurpose(sponsorId)) })),
    reward: stampRallyToken(secret, REWARD_PURPOSE),
    thanksCard: stampRallyToken(secret, THANKS_CARD_PURPOSE),
  };
}
