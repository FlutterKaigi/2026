/** 固定ウィンドウ方式のレート制限の状態。Firestore ドキュメントとしてそのまま保存する。 */
export interface AttemptWindow {
  readonly count: number;
  readonly windowStartMillis: number;
}

export interface RateLimitOptions {
  readonly maxAttempts: number;
  readonly windowMillis: number;
}

export interface RateLimitResult {
  readonly allowed: boolean;
  /** 呼び出し側が保存すべき次の状態（許可・拒否のいずれでも保存する）。 */
  readonly nextWindow: AttemptWindow;
}

/**
 * [previous] の状態に対して 1 回分の試行を記録し、許可するかどうかを判定する。
 *
 * 副作用を持たない純粋関数。呼び出し側（Firestore トランザクション内）が
 * [nextWindow] の保存と、拒否時のエラー送出を行う。
 */
export function recordAttempt(
  previous: AttemptWindow | undefined,
  nowMillis: number,
  options: RateLimitOptions,
): RateLimitResult {
  if (previous === undefined || nowMillis - previous.windowStartMillis >= options.windowMillis) {
    return { allowed: true, nextWindow: { count: 1, windowStartMillis: nowMillis } };
  }
  if (previous.count >= options.maxAttempts) {
    return { allowed: false, nextWindow: previous };
  }
  return { allowed: true, nextWindow: { count: previous.count + 1, windowStartMillis: previous.windowStartMillis } };
}
