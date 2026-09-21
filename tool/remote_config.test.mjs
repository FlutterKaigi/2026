import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { mergeDefaults, updateRemoteConfig } from './remote_config.mjs';

test('preserves unrelated parameters, groups and conditions without mutating the source', () => {
  const current = { version: { versionNumber: '8' }, conditions: [{ name: 'rollout' }],
    parameters: { unrelated: { conditionalValues: { rollout: { value: 'keep' } } } },
    parameterGroups: { conference: { description: 'keep', parameters: {
      event_features_enabled: { defaultValue: { value: 'true' }, valueType: 'BOOLEAN' },
    } } } };
  const before = structuredClone(current);
  const result = mergeDefaults(current, { event_features_enabled: { defaultValue: { value: 'false' }, valueType: 'BOOLEAN' } });
  assert.deepEqual(current, before);
  assert.deepEqual(result.parameters, current.parameters);
  assert.deepEqual(result.conditions, current.conditions);
  assert.equal(result.parameterGroups.conference.parameters.event_features_enabled.defaultValue.value, 'false');
  assert.equal(result.parameterGroups.conference.description, 'keep');
  assert.equal(result.version, undefined);
});

test('requires explicit review of targeted rollouts', () => {
  assert.throws(() => mergeDefaults({ parameters: {
    event_features_enabled: { conditionalValues: { reviewers: { value: 'true' } } },
  } }, { event_features_enabled: { defaultValue: { value: 'false' } } }), /条件付きの値/);
});

test('plan validates with the fetched ETag and never publishes', async () => {
  const calls = [];
  await updateRemoteConfig({ environment: 'prod', token: 'test-only', request: async (url, options) => {
    calls.push({ url, options });
    return new Response('{}', { status: 200, headers: { ETag: 'original-etag' } });
  } });
  assert.equal(calls.length, 2);
  assert.match(calls[1].url, /validate_only=true$/);
  assert.equal(calls[1].options.headers['If-Match'], 'original-etag');
  const body = JSON.parse(calls[1].options.body);
  assert.equal(body.parameters.event_features_enabled.defaultValue.value, 'true');
  assert.deepEqual(JSON.parse(body.parameters.force_update.defaultValue.value).minimum_version, { ios: '0.0.0', android: '0.0.0' });
});

test('a concurrent console edit fails without retry or force overwrite; the backup survives', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'flutterkaigi-rc-'));
  const backupPath = join(directory, 'before.json');
  const calls = [];
  try {
    await assert.rejects(updateRemoteConfig({ environment: 'stg', token: 'test-only', apply: true, backupPath,
      request: async (url, options) => {
        calls.push({ url, options });
        return new Response(calls.length === 1 ? '{"version":{"versionNumber":"9"}}' : '{}', {
          status: calls.length === 3 ? 412 : 200, headers: { ETag: 'original-etag' },
        });
      } }), /HTTP 412/);
    assert.equal(calls.length, 3);
    assert.equal(calls[2].options.headers['If-Match'], 'original-etag');
    assert.equal(JSON.parse(await readFile(backupPath, 'utf8')).version.versionNumber, '9');
  } finally {
    await rm(directory, { recursive: true });
  }
});
