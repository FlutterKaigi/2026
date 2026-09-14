import { HttpsError } from "firebase-functions/v2/https";

export type SupportLtGetUser = (uid: string) => Promise<{ disabled: boolean }>;

export class InactiveSupportLtUserError extends HttpsError {
  /** True when the Auth account no longer exists, as opposed to being disabled. */
  readonly deleted: boolean;

  constructor(disabled: boolean) {
    super(disabled ? "permission-denied" : "unauthenticated", disabled
      ? "このアカウントは利用できません。"
      : "アカウントが見つかりません。サインインし直してください。");
    this.deleted = !disabled;
  }
}

/** A token can outlive its Auth user. This check never writes or acquires locks. */
export async function assertActiveSupportLtUser(uid: string, getUser: SupportLtGetUser): Promise<void> {
  let user: { disabled: boolean };
  try {
    user = await getUser(uid);
  } catch (error) {
    if (typeof error !== "object" || error == null
      || !("code" in error) || error.code !== "auth/user-not-found") {
      throw error;
    }
    throw new InactiveSupportLtUserError(false);
  }
  if (user.disabled) throw new InactiveSupportLtUserError(true);
}
