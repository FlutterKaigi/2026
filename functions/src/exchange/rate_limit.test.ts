import assert from "node:assert/strict";
import { test } from "node:test";

import { recordAttempt } from "./rate_limit";

const OPTIONS = { maxAttempts: 3, windowMillis: 1000 };

test("recordAttempt starts a fresh window when there is no previous state", () => {
  const result = recordAttempt(undefined, 0, OPTIONS);
  assert.deepEqual(result, { allowed: true, nextWindow: { count: 1, windowStartMillis: 0 } });
});

test("recordAttempt increments the count while under the limit", () => {
  const first = recordAttempt(undefined, 0, OPTIONS);
  const second = recordAttempt(first.nextWindow, 100, OPTIONS);
  assert.deepEqual(second, { allowed: true, nextWindow: { count: 2, windowStartMillis: 0 } });
});

test("recordAttempt denies once the limit is reached within the window", () => {
  let window = recordAttempt(undefined, 0, OPTIONS).nextWindow;
  window = recordAttempt(window, 10, OPTIONS).nextWindow;
  window = recordAttempt(window, 20, OPTIONS).nextWindow;
  assert.equal(window.count, 3);

  const fourth = recordAttempt(window, 30, OPTIONS);
  assert.equal(fourth.allowed, false);
  // 拒否時も状態は変えない（無限にカウントを積み上げない）。
  assert.deepEqual(fourth.nextWindow, window);
});

test("recordAttempt resets the window once it has elapsed", () => {
  let window = recordAttempt(undefined, 0, OPTIONS).nextWindow;
  window = recordAttempt(window, 10, OPTIONS).nextWindow;
  window = recordAttempt(window, 20, OPTIONS).nextWindow;
  const denied = recordAttempt(window, 30, OPTIONS);
  assert.equal(denied.allowed, false);

  const afterWindow = recordAttempt(window, OPTIONS.windowMillis + 1, OPTIONS);
  assert.deepEqual(afterWindow, {
    allowed: true,
    nextWindow: { count: 1, windowStartMillis: OPTIONS.windowMillis + 1 },
  });
});
