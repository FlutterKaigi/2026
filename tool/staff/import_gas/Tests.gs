/**
 * Runs pure-function checks inside Apps Script. No Sheet, Drive, Storage, or
 * Firestore data is written.
 *
 * @return {number}
 */
function runStaffImportTests_() {
  var tests = [
    function () {
      assertStaffImportEqual_(normalizeAlias_('x', ' @Sample.\u200BUser '), 'sample.user');
    },
    function () {
      assertStaffImportEqual_(
        normalizeAlias_('bluesky', 'https://bsky.app/profile/sample.bsky.social'),
        'sample.bsky.social',
      );
    },
    function () {
      var links = buildSnsLinks_({x: '@sample_user', website: 'https://github.com/sample-user'});
      assertStaffImportDeepEqual_(links, [
        {type: 'x', value: 'https://x.com/sample_user'},
        {type: 'github', value: 'https://github.com/sample-user'},
      ]);
    },
    function () {
      assertStaffImportEqual_(
        extractDriveFileId_('https://drive.google.com/open?id=1AbCdEfGhIjKlMnOpQrStUvWxYz_12345'),
        '1AbCdEfGhIjKlMnOpQrStUvWxYz_12345',
      );
    },
    function () {
      var index = buildNameMapIndex_([
        {
          staffKey: 'sample-one',
          name: 'Sample One',
          aliasType: 'x',
          alias: 'sample_user',
          enabled: true,
        },
      ]);
      assertStaffImportDeepEqual_(resolveStaff_({x: '@sample_user'}, index), {
        staffKey: 'sample-one',
        name: 'Sample One',
      });
    },
    function () {
      var sameTime = new Date('2026-01-01T00:00:00Z');
      var result = selectLatestRows_([
        {staffKey: 'sample-one', rowNumber: 2, timestamp: sameTime},
        {staffKey: 'sample-one', rowNumber: 3, timestamp: sameTime},
      ]);
      assertStaffImportEqual_(result.selected[0].rowNumber, 3);
    },
    function () {
      var commit = buildFirestoreCommit_(
        'sample-project',
        'staff-sample-one',
        {name: 'Sample One', iconUrl: 'https://example.com/avatar', greeting: null, snsLinks: [], order: 1},
        null,
      );
      assertStaffImportDeepEqual_(commit.body.writes[0].currentDocument, {exists: false});
    },
    function () {
      assertStaffImportEqual_(
        stableStringify_({b: 2, a: 1}),
        stableStringify_({a: 1, b: 2}),
      );
    },
  ];

  tests.forEach(function (test, index) {
    try {
      test();
    } catch (error) {
      throw new Error('セルフテスト ' + (index + 1) + ' 失敗: ' + error.message);
    }
  });
  return tests.length;
}

/**
 * @param {*} actual
 * @param {*} expected
 */
function assertStaffImportEqual_(actual, expected) {
  if (actual !== expected) {
    throw new Error('expected=' + expected + ', actual=' + actual);
  }
}

/**
 * @param {*} actual
 * @param {*} expected
 */
function assertStaffImportDeepEqual_(actual, expected) {
  var actualJson = stableStringify_(actual);
  var expectedJson = stableStringify_(expected);
  if (actualJson !== expectedJson) {
    throw new Error('expected=' + expectedJson + ', actual=' + actualJson);
  }
}
