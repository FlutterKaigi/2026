function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('スタッフ取込')
    .addItem('初期セットアップ', 'setupStaffImport')
    .addSeparator()
    .addItem('STG 事前検証', 'validateStaffImportStg')
    .addItem('STG インポート', 'importStaffToStg')
    .addItem('本番インポート', 'importStaffToProd')
    .addSeparator()
    .addItem('セルフテスト', 'runStaffImportSelfTests')
    .addToUi();
}

function setupStaffImport() {
  runMenuAction_(function () {
    return withDocumentLock_(function () {
      var result = setupStaffImportSheet_();
      SpreadsheetApp.getUi().alert(
        '初期セットアップ完了',
        '回答シート: ' + result.sourceSheetName + '\n対応表: ' + result.mapSheetName,
        SpreadsheetApp.getUi().ButtonSet.OK,
      );
    });
  });
}

function validateStaffImportStg() {
  runMenuAction_(function () {
    return withDocumentLock_(function () {
      var summary = executeStaffImport_('STG', true);
      showImportSummary_('STG 事前検証', summary);
    });
  });
}

function importStaffToStg() {
  runMenuAction_(function () {
    var ui = SpreadsheetApp.getUi();
    var answer = ui.alert(
      'STG インポート',
      'STG の Storage と Firestore を更新します。続行しますか？',
      ui.ButtonSet.YES_NO,
    );
    if (answer !== ui.Button.YES) return;

    return withDocumentLock_(function () {
      var summary = executeStaffImport_('STG', false);
      showImportSummary_('STG インポート', summary);
    });
  });
}

function importStaffToProd() {
  runMenuAction_(function () {
    var ui = SpreadsheetApp.getUi();
    var answer = ui.prompt(
      '本番インポート',
      'STG と同じ入力を本番へ反映します。続行する場合は PROD と入力してください。',
      ui.ButtonSet.OK_CANCEL,
    );
    if (answer.getSelectedButton() !== ui.Button.OK) return;
    if (answer.getResponseText().trim() !== 'PROD') throw new Error('確認文字列が一致しません');

    return withDocumentLock_(function () {
      var summary = executeStaffImport_('PROD', false);
      showImportSummary_('本番インポート', summary);
    });
  });
}

function runStaffImportSelfTests() {
  runMenuAction_(function () {
    var count = runStaffImportTests_();
    SpreadsheetApp.getUi().alert('セルフテスト成功: ' + count + '件');
  });
}

/**
 * @param {'STG'|'PROD'} target
 * @param {boolean} dryRun
 * @return {Object<string, number>}
 */
function executeStaffImport_(target, dryRun) {
  var environment = getEnvironmentConfig_(target);
  var sourceSheet = getSourceSheet_();
  var rows = readSourceRows_(sourceSheet);
  var mapRows = readNameMapRows_();
  var outputTarget = dryRun ? 'VALIDATE' : target;

  rows.forEach(function (row) {
    row.result.importTarget = outputTarget;
    row.result.importStatus = '';
    row.result.importedAt = '';
    row.result.error = '';
  });

  try {
    if (rows.length === 0) throw new Error('フォーム回答がありません');
    var nameMapIndex;
    try {
      nameMapIndex = buildNameMapIndex_(mapRows);
    } catch (error) {
      rows.forEach(function (row) {
        setRowResult_(row, 'ERROR_VALIDATION', 'StaffNameMapの設定を確認してください');
      });
      throw error;
    }
    var resolvedRows = resolveImportRows_(rows, nameMapIndex);
    var latest = selectLatestRows_(resolvedRows);
    latest.duplicates.forEach(function (row) {
      setRowResult_(row, 'SKIPPED_DUPLICATE', '同じスタッフの新しい回答を採用しました');
    });

    var selected = assignOrders_(latest.selected);
    var preparedRows = prepareSelectedRows_(selected);
    if (selected.length === 0) throw new Error('取り込み対象がありません');

    var inputHash = computeInputHash_(mapRows, rows);
    var preflightHasErrors = hasErrorRows_(rows);
    if (dryRun) return summarizeRows_(rows);

    var documentProperties = getImportDocumentProperties_();
    if (target === 'PROD') {
      if (preflightHasErrors) throw new Error('事前検証エラーがあるため本番インポートできません');
      var stgHash = documentProperties.getProperty(
        STAFF_IMPORT_CONFIG.documentProperties.lastStgHash,
      );
      if (!stgHash || stgHash !== inputHash) {
        throw new Error('現在の入力は成功済みSTGデータと一致しません。STGから再実行してください');
      }
    } else {
      documentProperties.deleteProperty(STAFF_IMPORT_CONFIG.documentProperties.lastStgHash);
      documentProperties.deleteProperty(STAFF_IMPORT_CONFIG.documentProperties.lastStgAt);
    }

    preparedRows.forEach(function (row) {
      importPreparedRow_(environment, row);
    });

    if (target === 'STG' && !hasErrorRows_(rows)) {
      var successProperties = {};
      successProperties[STAFF_IMPORT_CONFIG.documentProperties.lastStgHash] = inputHash;
      successProperties[STAFF_IMPORT_CONFIG.documentProperties.lastStgAt] = new Date().toISOString();
      documentProperties.setProperties(successProperties, false);
    }
    return summarizeRows_(rows);
  } finally {
    writeImportResults_(sourceSheet, rows);
  }
}

/**
 * @param {Array<Object<string, *>>} rows
 * @param {{byAlias: Object<string, string>, byStaffKey: Object<string, *>}} nameMapIndex
 * @return {Array<Object<string, *>>}
 */
function resolveImportRows_(rows, nameMapIndex) {
  var resolved = [];
  rows.forEach(function (row) {
    if (!(row.timestamp instanceof Date) || !Number.isFinite(row.timestamp.getTime())) {
      setRowResult_(row, 'ERROR_VALIDATION', 'タイムスタンプが不正です');
      return;
    }

    try {
      var staff = resolveStaff_(row, nameMapIndex);
      if (!staff) {
        row.name = '';
        row.documentId = '';
        setRowResult_(row, 'SKIPPED_UNMAPPED', 'StaffNameMapに対応がありません');
        return;
      }
      row.staffKey = staff.staffKey;
      row.name = staff.name;
      row.documentId = 'staff-' + staff.staffKey;
      resolved.push(row);
    } catch (error) {
      setRowResult_(row, 'ERROR_VALIDATION', safeErrorMessage_(error));
    }
  });
  return resolved;
}

/**
 * @param {Array<Object<string, *>>} selectedRows
 * @return {Array<Object<string, *>>}
 */
function prepareSelectedRows_(selectedRows) {
  var prepared = [];
  selectedRows.forEach(function (row) {
    var greeting;
    var snsLinks;
    try {
      greeting = cleanCellText_(row.greeting) || null;
      snsLinks = buildSnsLinks_(row);
    } catch (error) {
      setRowResult_(row, 'ERROR_VALIDATION', safeErrorMessage_(error));
      return;
    }

    try {
      row.image = inspectDriveImage_(row.icon);
    } catch (error) {
      setRowResult_(row, 'SKIPPED_IMAGE', safeErrorMessage_(error));
      return;
    }

    row.firestoreData = {
      name: row.name,
      iconUrl: '',
      greeting: greeting,
      snsLinks: snsLinks,
      order: row.order,
    };
    row.warning = greeting && countCodePoints_(greeting) > 20
      ? 'ワンフレーズが20文字を超えています'
      : '';
    setRowResult_(row, 'READY', row.warning);
    prepared.push(row);
  });
  return prepared;
}

/**
 * @param {{target: string, projectId: string, bucket: string}} environment
 * @param {Object<string, *>} row
 */
function importPreparedRow_(environment, row) {
  var iconUrl;
  try {
    var blob = loadStaffAvatarBlob_(row.image);
    iconUrl = uploadStaffAvatar_(environment, row.staffKey, blob.getContentType(), blob);
  } catch (error) {
    if (error.fatal) {
      setRowResult_(row, 'ERROR_IMAGE', safeErrorMessage_(error));
      throw error;
    }
    setRowResult_(row, 'SKIPPED_IMAGE', safeErrorMessage_(error));
    return;
  }

  try {
    row.firestoreData.iconUrl = iconUrl;
    upsertStaffDocument_(environment, row.documentId, row.firestoreData);
    row.result.importedAt = new Date();
    setRowResult_(row, row.warning ? 'SUCCESS_WITH_WARNING' : 'SUCCESS', row.warning);
  } catch (error) {
    setRowResult_(row, 'ERROR_FIRESTORE', safeErrorMessage_(error));
    if (error.fatal) throw error;
  }
}

/**
 * @param {Array<Object<string, *>>} mapRows
 * @param {Array<Object<string, *>>} rows
 * @return {string}
 */
function computeInputHash_(mapRows, rows) {
  var payload = {
    transformVersion: STAFF_IMPORT_CONFIG.transformVersion,
    map: mapRows
      .filter(function (row) {
        return isEnabled_(row.enabled);
      })
      .map(function (row) {
        return {
          staffKey: cleanCellText_(row.staffKey),
          name: cleanCellText_(row.name),
          aliasType: cleanCellText_(row.aliasType).toLowerCase(),
          alias: normalizeAlias_(cleanCellText_(row.aliasType).toLowerCase(), row.alias),
        };
      }),
    rows: rows.map(function (row) {
      return {
        rowNumber: row.rowNumber,
        timestamp: row.timestamp instanceof Date ? row.timestamp.toISOString() : String(row.timestamp),
        source: {
          icon: row.icon,
          x: row.x,
          bluesky: row.bluesky,
          mixi2: row.mixi2,
          medium: row.medium,
          qiita: row.qiita,
          zenn: row.zenn,
          note: row.note,
          website: row.website,
          greeting: row.greeting,
        },
        staffKey: row.staffKey || null,
        order: row.order || null,
        image: row.image
          ? {
              fileId: row.image.fileId,
              mimeType: row.image.mimeType,
              size: row.image.size,
              lastUpdated: row.image.lastUpdated,
            }
          : null,
        firestoreData: row.firestoreData || null,
      };
    }),
  };
  var bytes = Utilities.computeDigest(
    Utilities.DigestAlgorithm.SHA_256,
    stableStringify_(payload),
    Utilities.Charset.UTF_8,
  );
  return bytes
    .map(function (value) {
      return ('0' + ((value + 256) % 256).toString(16)).slice(-2);
    })
    .join('');
}

/**
 * @param {Object<string, *>} row
 * @param {string} status
 * @param {string=} detail
 */
function setRowResult_(row, status, detail) {
  row.result.importStatus = status;
  row.result.error = detail || '';
  if (status !== 'SUCCESS' && status !== 'SUCCESS_WITH_WARNING') row.result.importedAt = '';
}

/**
 * @param {Array<Object<string, *>>} rows
 * @return {boolean}
 */
function hasErrorRows_(rows) {
  return rows.some(function (row) {
    return /^ERROR_/.test(row.result.importStatus);
  });
}

/**
 * @param {Array<Object<string, *>>} rows
 * @return {Object<string, number>}
 */
function summarizeRows_(rows) {
  var summary = {};
  rows.forEach(function (row) {
    var status = row.result.importStatus || 'UNPROCESSED';
    summary[status] = (summary[status] || 0) + 1;
  });
  return summary;
}

/**
 * @param {string} title
 * @param {Object<string, number>} summary
 */
function showImportSummary_(title, summary) {
  var message = Object.keys(summary)
    .sort()
    .map(function (status) {
      return status + ': ' + summary[status];
    })
    .join('\n');
  SpreadsheetApp.getUi().alert(title, message || '対象行なし', SpreadsheetApp.getUi().ButtonSet.OK);
}

/**
 * @param {function(): *} action
 * @return {*}
 */
function runMenuAction_(action) {
  try {
    return action();
  } catch (error) {
    SpreadsheetApp.getUi().alert('スタッフ取込エラー', safeErrorMessage_(error), SpreadsheetApp.getUi().ButtonSet.OK);
    return null;
  }
}

/**
 * @param {function(): *} action
 * @return {*}
 */
function withDocumentLock_(action) {
  var lock = LockService.getDocumentLock();
  if (!lock.tryLock(STAFF_IMPORT_CONFIG.lockTimeoutMs)) {
    throw new Error('別のスタッフ取込処理が実行中です');
  }
  try {
    return action();
  } finally {
    lock.releaseLock();
  }
}

/**
 * @param {*} error
 * @return {string}
 */
function safeErrorMessage_(error) {
  var message = String(error && error.message ? error.message : '不明なエラーです');
  return message.replace(/https?:\/\/\S+/g, '[URL]').slice(0, 200);
}
