import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import test from "node:test";

const generator = fileURLToPath(new URL("./generate_app_link_config.mjs", import.meta.url));
const hosts = JSON.parse(readFileSync(new URL("./app_link_hosts.json", import.meta.url), "utf8"));

function fixture(t, config = hosts) {
  const root = mkdtempSync(join(tmpdir(), "app-link-config-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  mkdirSync(join(root, "tool"));
  writeFileSync(join(root, "tool/app_link_hosts.json"), JSON.stringify(config));
  return root;
}

function run(root, ...args) {
  return spawnSync(process.execPath, [generator, "--root", root, ...args], { encoding: "utf8" });
}

test("generates identical Dart and JS origins and separate website metadata default", (t) => {
  const root = fixture(t);
  const result = run(root);
  assert.equal(result.status, 0, result.stderr);
  const dart = readFileSync(join(root, "packages/data/lib/src/app_link_origins.dart"), "utf8");
  const js = readFileSync(join(root, "tool/app_link_origins.mjs"), "utf8");
  const website = readFileSync(join(root, "apps/website/lib/constants/generated_link_origins.dart"), "utf8");
  for (const host of Object.values(hosts)) {
    assert.ok(dart.includes(`https://${host}`));
    assert.ok(js.includes(`https://${host}`));
  }
  assert.ok(website.includes(`https://${hosts.officialWebsiteHost}`));
  assert.ok(!website.includes(hosts.productionAppHost));
});

test("check detects stale output without rewriting it; regeneration repairs it", (t) => {
  const root = fixture(t);
  assert.equal(run(root).status, 0);
  const target = join(root, "tool/app_link_origins.mjs");
  writeFileSync(target, "stale\n");
  const result = run(root, "--check");
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /app_link_origins.mjs/);
  assert.equal(readFileSync(target, "utf8"), "stale\n");
  assert.equal(run(root).status, 0);
  assert.equal(run(root, "--check").status, 0);
});

test("check detects a changed manifest and missing generated files", (t) => {
  const root = fixture(t);
  assert.notEqual(run(root, "--check").status, 0);
  assert.equal(run(root).status, 0);
  writeFileSync(join(root, "tool/app_link_hosts.json"), JSON.stringify({ ...hosts, productionAppHost: "app.example.com" }));
  assert.notEqual(run(root, "--check").status, 0);
  assert.equal(run(root).status, 0);
  assert.equal(run(root, "--check").status, 0);
});

for (const invalidHost of ["https://example.com", "example.com/path", "example.com:443", "user@example.com", "example.com?x=1", "", "Example.com", "-app.example.com", "app..example.com"]) {
  test(`rejects invalid hostname ${JSON.stringify(invalidHost)} before writing`, (t) => {
    const root = fixture(t, { ...hosts, productionAppHost: invalidHost });
    const result = run(root);
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /productionAppHost/);
  });
}

test("rejects missing and unknown manifest keys and overlapping hosts", (t) => {
  for (const config of [
    { ...hosts, stagingAppHost: undefined },
    { ...hosts, accidentalHost: "example.com" },
    { ...hosts, stagingAppHost: hosts.productionAppHost },
  ]) {
    assert.notEqual(run(fixture(t, config)).status, 0);
  }
});

test("rejects unsupported CLI arguments", (t) => {
  assert.notEqual(run(fixture(t), "--unexpected").status, 0);
  const result = spawnSync(process.execPath, [generator, "--unexpected", "--check"], { encoding: "utf8" });
  assert.notEqual(result.status, 0);
});
