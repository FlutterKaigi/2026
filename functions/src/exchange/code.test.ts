import assert from "node:assert/strict";
import { test } from "node:test";

import { EXCHANGE_CODE_LENGTH, generateExchangeCode, isValidExchangeCodeFormat } from "./code";

test("generateExchangeCode zero-pads a small random value to 6 digits", () => {
  const code = generateExchangeCode(() => 7);
  assert.equal(code, "000007");
  assert.equal(code.length, EXCHANGE_CODE_LENGTH);
});

test("generateExchangeCode passes the full range through untouched", () => {
  const code = generateExchangeCode(() => 999999);
  assert.equal(code, "999999");
});

test("isValidExchangeCodeFormat accepts exactly 6 digits", () => {
  assert.equal(isValidExchangeCodeFormat("012345"), true);
  assert.equal(isValidExchangeCodeFormat("999999"), true);
});

test("isValidExchangeCodeFormat rejects anything else", () => {
  assert.equal(isValidExchangeCodeFormat("12345"), false);
  assert.equal(isValidExchangeCodeFormat("1234567"), false);
  assert.equal(isValidExchangeCodeFormat("12345a"), false);
  assert.equal(isValidExchangeCodeFormat(""), false);
  assert.equal(isValidExchangeCodeFormat(" 12345"), false);
});
