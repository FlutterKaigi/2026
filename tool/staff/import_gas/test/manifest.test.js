const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const manifestPath = path.resolve(__dirname, '..', 'appsscript.json');

test('manifest keeps the required URL fetch prefixes and OAuth scopes', () => {
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

  assert.deepEqual(manifest.urlFetchWhitelist, [
    'https://firestore.googleapis.com/',
    'https://storage.googleapis.com/',
    'https://www.googleapis.com/drive/v3/',
    'https://docs.google.com/feeds/vt',
    'https://*.googleusercontent.com/',
  ]);
  assert.deepEqual(manifest.oauthScopes, [
    'https://www.googleapis.com/auth/spreadsheets.currentonly',
    'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/script.external_request',
    'https://www.googleapis.com/auth/datastore',
    'https://www.googleapis.com/auth/devstorage.full_control',
  ]);
});
