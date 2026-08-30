import assert from "node:assert/strict";
import { test } from "node:test";

import { EXCHANGE_TOKEN_TTL_SECONDS, signExchangeToken, verifyExchangeToken } from "./token";

const SECRET = "test-secret";
const NOW_MILLIS = Date.parse("2026-08-30T00:00:00Z");

test("signExchangeToken issues a v1 token verifiable for the same uid", () => {
  const token = signExchangeToken("uid-1", SECRET, NOW_MILLIS);
  assert.match(token, /^v1\.uid-1\.\d+\.[A-Za-z0-9_-]+$/);

  const result = verifyExchangeToken(token, SECRET, NOW_MILLIS);
  assert.deepEqual(result, { valid: true, uid: "uid-1" });
});

test("verifyExchangeToken accepts a token right up to its expiry", () => {
  const token = signExchangeToken("uid-1", SECRET, NOW_MILLIS);
  const justBeforeExpiry = NOW_MILLIS + EXCHANGE_TOKEN_TTL_SECONDS * 1000;

  const result = verifyExchangeToken(token, SECRET, justBeforeExpiry);
  assert.equal(result.valid, true);
});

test("verifyExchangeToken rejects a token once its expiry has passed", () => {
  const token = signExchangeToken("uid-1", SECRET, NOW_MILLIS);
  const afterExpiry = NOW_MILLIS + (EXCHANGE_TOKEN_TTL_SECONDS + 1) * 1000;

  const result = verifyExchangeToken(token, SECRET, afterExpiry);
  assert.deepEqual(result, { valid: false, reason: "expired" });
});

test("verifyExchangeToken rejects a token signed with a different secret", () => {
  const token = signExchangeToken("uid-1", SECRET, NOW_MILLIS);

  const result = verifyExchangeToken(token, "another-secret", NOW_MILLIS);
  assert.deepEqual(result, { valid: false, reason: "bad-signature" });
});

test("verifyExchangeToken rejects a tampered uid even with a structurally valid signature copied over", () => {
  const token = signExchangeToken("uid-1", SECRET, NOW_MILLIS);
  const [version, , exp, signature] = token.split(".");
  const tampered = [version, "uid-2", exp, signature].join(".");

  const result = verifyExchangeToken(tampered, SECRET, NOW_MILLIS);
  assert.deepEqual(result, { valid: false, reason: "bad-signature" });
});

test("verifyExchangeToken rejects malformed input", () => {
  assert.deepEqual(verifyExchangeToken("not-a-token", SECRET, NOW_MILLIS), {
    valid: false,
    reason: "malformed",
  });
  assert.deepEqual(verifyExchangeToken("v1..123.sig", SECRET, NOW_MILLIS), {
    valid: false,
    reason: "malformed",
  });
  assert.deepEqual(verifyExchangeToken("v1.uid-1.not-a-number.sig", SECRET, NOW_MILLIS), {
    valid: false,
    reason: "malformed",
  });
});

test("verifyExchangeToken rejects an unsupported version", () => {
  const result = verifyExchangeToken("v2.uid-1.9999999999.sig", SECRET, NOW_MILLIS);
  assert.deepEqual(result, { valid: false, reason: "unsupported-version" });
});

test("signExchangeToken rejects a uid containing '.'", () => {
  assert.throws(() => signExchangeToken("uid.1", SECRET, NOW_MILLIS), RangeError);
});
