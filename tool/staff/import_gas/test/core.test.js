const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const gasDir = path.resolve(__dirname, '..');

function loadGas(files) {
  const context = vm.createContext({
    console,
    Date,
    encodeURIComponent,
    JSON,
    Object,
    RegExp,
    Set,
    String,
  });

  for (const file of files) {
    const filePath = path.join(gasDir, file);
    if (!fs.existsSync(filePath)) continue;
    vm.runInContext(fs.readFileSync(filePath, 'utf8'), context, {filename: filePath});
  }

  return context;
}

function plain(value) {
  return JSON.parse(JSON.stringify(value));
}

test('normalizeAlias_ removes presentation-only characters', () => {
  const gas = loadGas(['Transform.gs']);

  assert.equal(gas.normalizeAlias_('x', '  @Endo.\u200BTakumi  '), 'endo.takumi');
});

test('normalizeAlias_ extracts handles from profile URLs', () => {
  const gas = loadGas(['Transform.gs']);

  assert.equal(gas.normalizeAlias_('x', 'https://x.com/Example_User/'), 'example_user');
  assert.equal(
    gas.normalizeAlias_('bluesky', 'https://bsky.app/profile/example.bsky.social'),
    'example.bsky.social',
  );
});

test('buildSnsLinks_ creates canonical, unique links in column order', () => {
  const gas = loadGas(['Transform.gs']);

  const links = gas.buildSnsLinks_({
    x: '@Example_User',
    bluesky: '@example.bsky.social',
    mixi2: '@example',
    medium: 'portfolio.example.com',
    qiita: 'https://qiita.com/example',
    zenn: 'example',
    note: 'example',
    website: 'https://github.com/example',
  });

  assert.deepEqual(plain(links), [
    {type: 'x', value: 'https://x.com/Example_User'},
    {type: 'bluesky', value: 'https://bsky.app/profile/example.bsky.social'},
    {type: 'mixi2', value: 'https://mixi.social/@example'},
    {type: 'web', value: 'https://portfolio.example.com'},
    {type: 'qiita', value: 'https://qiita.com/example'},
    {type: 'zenn', value: 'https://zenn.dev/example'},
    {type: 'note', value: 'https://note.com/example'},
    {type: 'github', value: 'https://github.com/example'},
  ]);
});

test('buildSnsLinks_ rejects a non-HTTP website value', () => {
  const gas = loadGas(['Transform.gs']);

  assert.throws(
    () => gas.buildSnsLinks_({website: 'javascript:alert(1)'}),
    /URLが不正です/,
  );
});

test('extractDriveFileId_ supports Google Forms file URLs', () => {
  const gas = loadGas(['DriveImage.gs']);

  assert.equal(
    gas.extractDriveFileId_('https://drive.google.com/open?id=1AbCdEfGhIjKlMnOpQrStUvWxYz_12345'),
    '1AbCdEfGhIjKlMnOpQrStUvWxYz_12345',
  );
  assert.equal(
    gas.extractDriveFileId_('https://drive.google.com/file/d/1AbCdEfGhIjKlMnOpQrStUvWxYz_12345/view'),
    '1AbCdEfGhIjKlMnOpQrStUvWxYz_12345',
  );
});

test('buildDriveThumbnailUrl_ requests a 320px square webp thumbnail', () => {
  const gas = loadGas(['DriveImage.gs']);

  // lh3 形式: 末尾のオプション列を差し替える
  assert.equal(
    gas.buildDriveThumbnailUrl_('https://lh3.googleusercontent.com/drive-storage/AbC_1-2=s220', 320),
    'https://lh3.googleusercontent.com/drive-storage/AbC_1-2=s320-c-rw',
  );
  // オプション列が無い場合は付与する
  assert.equal(
    gas.buildDriveThumbnailUrl_('https://lh3.googleusercontent.com/drive-storage/AbC_1-2', 320),
    'https://lh3.googleusercontent.com/drive-storage/AbC_1-2=s320-c-rw',
  );
  // feeds/vt 形式: sz クエリだけを差し替え、webp は要求しない
  assert.equal(
    gas.buildDriveThumbnailUrl_('https://docs.google.com/feeds/vt?id=abc&sz=s220&v=1', 320),
    'https://docs.google.com/feeds/vt?id=abc&sz=s320&v=1',
  );
  assert.equal(gas.buildDriveThumbnailUrl_('', 320), '');
});

test('normalizeImageContentType_ accepts only supported image types', () => {
  const gas = loadGas(['DriveImage.gs']);

  assert.equal(gas.normalizeImageContentType_('image/webp'), 'image/webp');
  assert.equal(gas.normalizeImageContentType_('IMAGE/PNG; charset=binary'), 'image/png');
  // サムネイル生成失敗時はエラーページが返るため、画像以外は弾く
  assert.equal(gas.normalizeImageContentType_('text/html'), '');
  assert.equal(gas.normalizeImageContentType_(null), '');
});

test('resolveStaff_ maps a normalized account alias to a stable staff key', () => {
  const gas = loadGas(['Transform.gs']);
  const index = gas.buildNameMapIndex_([
    {
      staffKey: 'sample-one',
      name: 'Sample One',
      aliasType: 'x',
      alias: 'Sample_User',
      enabled: true,
    },
  ]);

  assert.deepEqual(
    plain(gas.resolveStaff_({x: '@sample_user', documentId: ''}, index)),
    {staffKey: 'sample-one', name: 'Sample One'},
  );
});

test('selectLatestRows_ keeps the newest response per staff key', () => {
  const gas = loadGas(['Transform.gs']);
  const result = gas.selectLatestRows_([
    {staffKey: 'sample-one', rowNumber: 2, timestamp: new Date('2026-01-01T00:00:00Z')},
    {staffKey: 'sample-two', rowNumber: 3, timestamp: new Date('2026-01-02T00:00:00Z')},
    {staffKey: 'sample-one', rowNumber: 4, timestamp: new Date('2026-02-01T00:00:00Z')},
  ]);

  assert.deepEqual(
    plain({
      selected: result.selected.map((row) => row.rowNumber),
      duplicates: result.duplicates.map((row) => row.rowNumber),
    }),
    {selected: [3, 4], duplicates: [2]},
  );
});

test('assignOrders_ numbers selected rows in sheet order', () => {
  const gas = loadGas(['Transform.gs']);

  const ordered = gas.assignOrders_([
    {staffKey: 'sample-two', rowNumber: 8},
    {staffKey: 'sample-one', rowNumber: 3},
  ]);

  assert.deepEqual(
    plain(ordered.map((row) => ({rowNumber: row.rowNumber, order: row.order}))),
    [
      {rowNumber: 3, order: 1},
      {rowNumber: 8, order: 2},
    ],
  );
});

test('buildFirestoreCommit_ creates a typed document with server timestamps', () => {
  const gas = loadGas(['Firestore.gs']);

  const request = gas.buildFirestoreCommit_(
    'sample-project',
    'staff-sample-one',
    {
      name: 'Sample One',
      iconUrl: 'https://example.com/avatar.png',
      greeting: null,
      snsLinks: [{type: 'x', value: 'https://x.com/sample_one'}],
      order: 1,
    },
    null,
  );

  const write = request.body.writes[0];
  assert.equal(
    request.url,
    'https://firestore.googleapis.com/v1/projects/sample-project/databases/(default)/documents:commit',
  );
  assert.equal(
    write.update.name,
    'projects/sample-project/databases/(default)/documents/staffMembers/staff-sample-one',
  );
  assert.deepEqual(plain(write.update.fields.order), {integerValue: '1'});
  assert.deepEqual(plain(write.update.fields.greeting), {nullValue: null});
  assert.deepEqual(plain(write.currentDocument), {exists: false});
  assert.deepEqual(plain(write.updateTransforms), [
    {fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME'},
    {fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME'},
  ]);
});

test('buildFirestoreCommit_ preserves createdAt on a conditional update', () => {
  const gas = loadGas(['Firestore.gs']);

  const request = gas.buildFirestoreCommit_(
    'sample-project',
    'staff-sample-one',
    {
      name: 'Sample One',
      iconUrl: 'https://example.com/avatar.png',
      greeting: 'Hello',
      snsLinks: [],
      order: 2,
    },
    {updateTime: '2026-08-01T00:00:00Z'},
  );

  const write = request.body.writes[0];
  assert.deepEqual(plain(write.currentDocument), {updateTime: '2026-08-01T00:00:00Z'});
  assert.deepEqual(plain(write.updateMask.fieldPaths), [
    'name',
    'iconUrl',
    'greeting',
    'snsLinks',
    'order',
  ]);
  assert.deepEqual(plain(write.updateTransforms), [
    {fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME'},
  ]);
});

test('buildFirebaseDownloadUrl_ encodes the stable object path', () => {
  const gas = loadGas(['FirebaseStorage.gs']);

  assert.equal(
    gas.buildFirebaseDownloadUrl_(
      'sample-project.firebasestorage.app',
      'public/staff/sample-one/avatar',
      'sample-token',
    ),
    'https://firebasestorage.googleapis.com/v0/b/sample-project.firebasestorage.app/o/' +
      'public%2Fstaff%2Fsample-one%2Favatar?alt=media&token=sample-token',
  );
});

test('uploadStaffAvatar_ uploads existing-token metadata and image bytes in one multipart request', () => {
  const gas = loadGas(['FirebaseStorage.gs']);
  const calls = [];
  const imageBytes = [0, 255, 128, 10, 13, 42];
  const response = (code, body) => ({
    getResponseCode: () => code,
    getContentText: () => JSON.stringify(body),
  });
  gas.Utilities = {
    getUuid: () => 'multipart-boundary-id',
    newBlob: (text) => ({getBytes: () => Array.from(Buffer.from(text, 'utf8'))}),
  };
  gas.parseJsonResponse_ = (value) => JSON.parse(value.getContentText());
  gas.fetchWithRetry_ = (url, options, acceptedCodes) => {
    calls.push({url, options, acceptedCodes});
    if (calls.length === 1) {
      return response(200, {
        generation: '17',
        metadata: {firebaseStorageDownloadTokens: 'existing-token,older-token'},
      });
    }
    return response(200, {generation: '18'});
  };

  const downloadUrl = gas.uploadStaffAvatar_(
    {bucket: 'sample-project.firebasestorage.app'},
    'sample-one',
    'image/png',
    {getBytes: () => imageBytes.slice()},
  );

  assert.equal(calls.length, 2);
  assert.equal(calls[0].options.method, 'get');
  assert.match(calls[0].url, /public%2Fstaff%2Fsample-one%2Favatar\?fields=/);
  assert.equal(calls[1].options.method, 'post');
  assert.equal(
    calls[1].url,
    'https://storage.googleapis.com/upload/storage/v1/b/sample-project.firebasestorage.app/o' +
      '?uploadType=multipart&ifGenerationMatch=17',
  );
  assert.doesNotMatch(calls.map((call) => call.options.method).join(','), /patch/i);

  const boundary = calls[1].options.contentType.match(/^multipart\/related; boundary=(.+)$/)[1];
  const payload = Buffer.from(calls[1].options.payload);
  const metadataStart = Buffer.from(
    `--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n`,
  );
  const imageStart = Buffer.from(`\r\n--${boundary}\r\nContent-Type: image/png\r\n\r\n`);
  const imageEnd = Buffer.from(`\r\n--${boundary}--\r\n`);
  assert.equal(payload.subarray(0, metadataStart.length).equals(metadataStart), true);
  const imageOffset = payload.indexOf(imageStart, metadataStart.length);
  const endOffset = payload.indexOf(imageEnd, imageOffset + imageStart.length);
  const metadata = JSON.parse(payload.subarray(metadataStart.length, imageOffset).toString('utf8'));
  assert.deepEqual(metadata, {
    name: 'public/staff/sample-one/avatar',
    contentType: 'image/png',
    cacheControl: 'public,max-age=3600',
    metadata: {firebaseStorageDownloadTokens: 'existing-token'},
  });
  assert.deepEqual(
    [...payload.subarray(imageOffset + imageStart.length, endOffset)],
    imageBytes,
  );
  assert.equal(
    downloadUrl,
    'https://firebasestorage.googleapis.com/v0/b/sample-project.firebasestorage.app/o/' +
      'public%2Fstaff%2Fsample-one%2Favatar?alt=media&token=existing-token',
  );
});

test('uploadStaffAvatar_ generates a token and uses generation zero for a new object', () => {
  const gas = loadGas(['FirebaseStorage.gs']);
  const calls = [];
  const uuids = ['new-token', 'multipart-boundary-id'];
  gas.Utilities = {
    getUuid: () => uuids.shift(),
    newBlob: (text) => ({getBytes: () => Array.from(Buffer.from(text, 'utf8'))}),
  };
  gas.fetchWithRetry_ = (url, options, acceptedCodes) => {
    calls.push({url, options, acceptedCodes});
    return calls.length === 1
      ? {getResponseCode: () => 404}
      : {getResponseCode: () => 200, getContentText: () => '{}'};
  };

  const downloadUrl = gas.uploadStaffAvatar_(
    {bucket: 'sample-project.firebasestorage.app'},
    'sample-two',
    'image/jpeg',
    {getBytes: () => [1, 2, 3]},
  );

  assert.equal(calls.length, 2);
  assert.deepEqual(uuids, []);
  assert.match(calls[1].url, /\?uploadType=multipart&ifGenerationMatch=0$/);
  assert.match(
    Buffer.from(calls[1].options.payload).toString('latin1'),
    /"firebaseStorageDownloadTokens":"new-token"/,
  );
  assert.match(downloadUrl, /token=new-token$/);
});

test('stableStringify_ is deterministic across object key order', () => {
  const gas = loadGas(['Transform.gs']);

  assert.equal(
    gas.stableStringify_({b: 2, a: {d: 4, c: 3}}),
    gas.stableStringify_({a: {c: 3, d: 4}, b: 2}),
  );
});

test('resolveHeaderIndexes_ finds logical columns without relying on position', () => {
  const gas = loadGas(['SheetRepository.gs']);

  const result = gas.resolveHeaderIndexes_(
    [' X account ', 'Timestamp', 'importStatus'],
    {timestamp: 'Timestamp', x: 'X account'},
  );

  assert.deepEqual(plain(result), {timestamp: 1, x: 0});
});

test('runWithRetry_ retries only retryable responses with backoff', () => {
  const gas = loadGas(['Http.gs']);
  let attempts = 0;
  const waits = [];

  const result = gas.runWithRetry_(
    () => ({code: ++attempts < 3 ? 500 : 200}),
    (response) => response.code >= 500,
    (milliseconds) => waits.push(milliseconds),
    [1000, 2000, 4000],
  );

  assert.equal(result.code, 200);
  assert.equal(attempts, 3);
  assert.deepEqual(waits, [1000, 2000]);
});

test('fetchWithRetry_ reports sanitized endpoint and Google API error details', () => {
  const gas = loadGas(['Http.gs', 'Code.gs']);
  const response = {
    getResponseCode: () => 403,
    getContentText: () =>
      JSON.stringify({
        error: {
          message: 'The caller does not have permission.',
          status: 'PERMISSION_DENIED',
          errors: [{reason: 'forbidden'}],
        },
      }),
  };
  gas.ScriptApp = {getOAuthToken: () => 'secret-oauth-token'};
  gas.UrlFetchApp = {fetch: () => response};
  gas.Utilities = {sleep: () => assert.fail('403 responses must not be retried')};

  assert.throws(
    () =>
      gas.fetchWithRetry_(
        'https://firestore.googleapis.com/v1/projects/sample?access_token=secret#fragment',
        {method: 'post', payload: 'private-request-body'},
      ),
    (error) => {
      assert.equal(
        error.message,
        'Google API request failed (HTTP 403) POST ' +
          'firestore.googleapis.com/v1/projects/sample: ' +
          'The caller does not have permission.; status=PERMISSION_DENIED; reason=forbidden',
      );
      assert.equal(error.statusCode, 403);
      assert.equal(error.fatal, true);
      assert.doesNotMatch(error.message, /access_token|secret|fragment|private-request-body/);
      assert.match(
        gas.safeErrorMessage_(error),
        /POST firestore\.googleapis\.com\/v1\/projects\/sample:/,
      );
      assert.doesNotMatch(gas.safeErrorMessage_(error), /\[URL\]/);
      return true;
    },
  );
});

test('fetchWithRetry_ normalizes and truncates a non-JSON error response', () => {
  const gas = loadGas(['Http.gs']);
  const response = {
    getResponseCode: () => 400,
    getContentText: () => '  Invalid\n\trequest ' + 'x'.repeat(400),
  };
  gas.ScriptApp = {getOAuthToken: () => 'secret-oauth-token'};
  gas.UrlFetchApp = {fetch: () => response};
  gas.Utilities = {sleep: () => assert.fail('400 responses must not be retried')};

  assert.throws(() => gas.fetchWithRetry_('https://example.test/resource', {}), (error) => {
    assert.match(
      error.message,
      /^Google API request failed \(HTTP 400\) GET example\.test\/resource:/,
    );
    assert.match(error.message, /: Invalid request x+\.\.\.$/);
    assert.equal(error.message.split(': ')[1].length, 300);
    assert.equal(error.statusCode, 400);
    assert.equal(error.fatal, undefined);
    return true;
  });
});

test('fetchWithRetry_ omits detail punctuation for an empty error response', () => {
  const gas = loadGas(['Http.gs']);
  const response = {getResponseCode: () => 404, getContentText: () => '  \n '};
  gas.ScriptApp = {getOAuthToken: () => 'secret-oauth-token'};
  gas.UrlFetchApp = {fetch: () => response};
  gas.Utilities = {sleep: () => assert.fail('404 responses must not be retried')};

  assert.throws(
    () => gas.fetchWithRetry_('https://example.test/missing?key=private', {method: 'HEAD'}),
    (error) => {
      assert.equal(
        error.message,
        'Google API request failed (HTTP 404) HEAD example.test/missing',
      );
      return true;
    },
  );
});

test('countCodePoints_ counts an emoji as one character', () => {
  const gas = loadGas(['Transform.gs']);

  assert.equal(gas.countCodePoints_('A😀B'), 3);
});

test('all Apps Script sources load in one V8 context', () => {
  const gas = loadGas([
    'Config.gs',
    'Transform.gs',
    'SheetRepository.gs',
    'DriveImage.gs',
    'Http.gs',
    'FirebaseStorage.gs',
    'Firestore.gs',
    'Tests.gs',
    'Code.gs',
  ]);

  assert.equal(typeof gas.onOpen, 'function');
  assert.equal(typeof gas.executeStaffImport_, 'function');
  assert.equal(typeof gas.runStaffImportTests_, 'function');
});

test('Apps Script self-test suite passes locally', () => {
  const gas = loadGas([
    'Transform.gs',
    'DriveImage.gs',
    'Firestore.gs',
    'Tests.gs',
  ]);

  assert.equal(gas.runStaffImportTests_(), 8);
});

test('executeStaffImport_ validates, deduplicates, and writes row results', () => {
  const gas = loadGas([
    'Config.gs',
    'Transform.gs',
    'DriveImage.gs',
    'SheetRepository.gs',
    'Code.gs',
  ]);
  const rows = [
    {
      rowNumber: 2,
      timestamp: new Date('2026-01-01T00:00:00Z'),
      icon: 'old-image',
      x: 'sample_user',
      bluesky: '',
      mixi2: '',
      medium: '',
      qiita: '',
      zenn: '',
      note: '',
      website: '',
      greeting: '',
      name: '',
      documentId: '',
      result: {},
    },
    {
      rowNumber: 3,
      timestamp: new Date('2026-02-01T00:00:00Z'),
      icon: 'new-image',
      x: 'sample_user',
      bluesky: '',
      mixi2: '',
      medium: '',
      qiita: '',
      zenn: '',
      note: '',
      website: '',
      greeting: 'Hello',
      name: '',
      documentId: '',
      result: {},
    },
    {
      rowNumber: 4,
      timestamp: new Date('2026-03-01T00:00:00Z'),
      icon: 'unmapped-image',
      x: 'unknown_user',
      bluesky: '',
      mixi2: '',
      medium: '',
      qiita: '',
      zenn: '',
      note: '',
      website: '',
      greeting: '',
      name: '',
      documentId: '',
      result: {},
    },
  ];
  let writtenRows;

  gas.getEnvironmentConfig_ = () => ({target: 'STG', projectId: 'sample-project', bucket: 'sample'});
  gas.getSourceSheet_ = () => ({});
  gas.readSourceRows_ = () => rows;
  gas.readNameMapRows_ = () => [
    {
      staffKey: 'sample-one',
      name: 'Sample One',
      aliasType: 'x',
      alias: 'sample_user',
      enabled: true,
    },
  ];
  gas.inspectDriveImage_ = () => ({
    fileId: 'sample-file-id',
    mimeType: 'image/png',
    size: 123,
    lastUpdated: '2026-01-01T00:00:00Z',
  });
  gas.computeInputHash_ = () => 'sample-hash';
  gas.writeImportResults_ = (_sheet, resultRows) => {
    writtenRows = resultRows;
  };

  const summary = gas.executeStaffImport_('STG', true);

  assert.deepEqual(plain(summary), {SKIPPED_DUPLICATE: 1, READY: 1, SKIPPED_UNMAPPED: 1});
  assert.equal(writtenRows[1].order, 1);
  assert.equal(writtenRows[1].documentId, 'staff-sample-one');
});

test('prepareSelectedRows_ skips unreadable, unsupported, and oversized images', () => {
  const gas = loadGas(['Code.gs']);
  const rows = [
    {icon: 'unreadable-image', name: 'Skipped', order: 1, result: {}},
    {icon: 'unsupported-image', name: 'Skipped', order: 2, result: {}},
    {icon: 'oversized-image', name: 'Skipped', order: 3, result: {}},
    {icon: 'valid-image', name: 'Ready', order: 4, result: {}},
  ];

  gas.cleanCellText_ = (value) => value || '';
  gas.buildSnsLinks_ = () => [];
  gas.countCodePoints_ = (value) => [...value].length;
  gas.inspectDriveImage_ = (icon) => {
    const messages = {
      'unreadable-image': 'Drive画像を参照できません',
      'unsupported-image': '未対応の画像形式です',
      'oversized-image': '画像サイズが上限を超えています',
    };
    if (messages[icon]) throw new Error(messages[icon]);
    return {fileId: 'valid-file-id', mimeType: 'image/png', size: 123};
  };

  const prepared = gas.prepareSelectedRows_(rows);

  assert.deepEqual(plain(prepared.map((row) => row.name)), ['Ready']);
  assert.equal(rows[0].result.importStatus, 'SKIPPED_IMAGE');
  assert.equal(rows[0].result.error, 'Drive画像を参照できません');
  assert.equal(rows[1].result.importStatus, 'SKIPPED_IMAGE');
  assert.equal(rows[2].result.importStatus, 'SKIPPED_IMAGE');
  assert.equal(rows[3].result.importStatus, 'READY');
  assert.equal(gas.hasErrorRows_(rows), false);
});

test('importPreparedRow_ skips a non-fatal image upload failure before Firestore', () => {
  const gas = loadGas(['Code.gs']);
  const row = {
    image: {fileId: 'sample-file-id'},
    staffKey: 'sample-one',
    documentId: 'staff-sample-one',
    firestoreData: {iconUrl: ''},
    result: {},
  };
  let firestoreWrites = 0;

  gas.loadStaffAvatarBlob_ = () => ({getContentType: () => 'image/webp'});
  gas.uploadStaffAvatar_ = () => {
    throw new Error('Storage upload failed');
  };
  gas.upsertStaffDocument_ = () => {
    firestoreWrites += 1;
  };

  gas.importPreparedRow_({target: 'STG'}, row);

  assert.equal(row.result.importStatus, 'SKIPPED_IMAGE');
  assert.equal(row.result.error, 'Storage upload failed');
  assert.equal(firestoreWrites, 0);
});

test('importPreparedRow_ preserves and rethrows a fatal image upload failure', () => {
  const gas = loadGas(['Code.gs']);
  const row = {
    image: {fileId: 'sample-file-id'},
    staffKey: 'sample-one',
    documentId: 'staff-sample-one',
    firestoreData: {iconUrl: ''},
    result: {},
  };
  const fatalError = new Error('Storage authorization failed');
  fatalError.fatal = true;

  gas.loadStaffAvatarBlob_ = () => ({getContentType: () => 'image/webp'});
  gas.uploadStaffAvatar_ = () => {
    throw fatalError;
  };
  gas.upsertStaffDocument_ = () => {
    assert.fail('Firestore must not be called after a fatal image upload failure');
  };

  assert.throws(() => gas.importPreparedRow_({target: 'STG'}, row), (error) => error === fatalError);
  assert.equal(row.result.importStatus, 'ERROR_IMAGE');
  assert.equal(row.result.error, 'Storage authorization failed');
});
