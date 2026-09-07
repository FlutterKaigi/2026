/**
 * @param {Array<*>} headers
 * @param {Object<string, string>} requiredHeaders
 * @return {Object<string, number>}
 */
function resolveHeaderIndexes_(headers, requiredHeaders) {
  var positions = {};
  headers.forEach(function (header, index) {
    var normalized = normalizeHeader_(header);
    if (!positions[normalized]) positions[normalized] = [];
    positions[normalized].push(index);
  });

  var result = {};
  Object.keys(requiredHeaders).forEach(function (logicalName) {
    var expected = normalizeHeader_(requiredHeaders[logicalName]);
    var indexes = positions[expected] || [];
    if (indexes.length === 0) throw new Error('必須ヘッダーがありません: ' + requiredHeaders[logicalName]);
    if (indexes.length > 1) throw new Error('ヘッダーが重複しています: ' + requiredHeaders[logicalName]);
    result[logicalName] = indexes[0];
  });
  return result;
}

/**
 * @param {*} value
 * @return {string}
 */
function normalizeHeader_(value) {
  return String(value == null ? '' : value).trim().replace(/\s+/g, ' ');
}

/**
 * Creates only missing management structures and records the active response
 * sheet by numeric ID.
 *
 * @return {{sourceSheetName: string, mapSheetName: string}}
 */
function setupStaffImportSheet_() {
  var spreadsheet = SpreadsheetApp.getActive();
  var sourceSheet = spreadsheet.getActiveSheet();
  if (sourceSheet.getName() === STAFF_IMPORT_CONFIG.mapSheetName) {
    throw new Error('フォーム回答シートを開いてから初期セットアップを実行してください');
  }

  var headers = sourceSheet.getRange(1, 1, 1, sourceSheet.getLastColumn()).getDisplayValues()[0];
  resolveHeaderIndexes_(headers, STAFF_IMPORT_CONFIG.sourceHeaders);
  ensureManagementHeaders_(sourceSheet);
  ensureNameMapSheet_(spreadsheet);

  getImportDocumentProperties_().setProperty(
    STAFF_IMPORT_CONFIG.documentProperties.sourceSheetId,
    String(sourceSheet.getSheetId()),
  );
  return {sourceSheetName: sourceSheet.getName(), mapSheetName: STAFF_IMPORT_CONFIG.mapSheetName};
}

/**
 * @param {GoogleAppsScript.Spreadsheet.Sheet} sheet
 */
function ensureManagementHeaders_(sheet) {
  var lastColumn = sheet.getLastColumn();
  var headers = sheet.getRange(1, 1, 1, lastColumn).getDisplayValues()[0];
  var normalized = {};
  headers.forEach(function (header) {
    normalized[normalizeHeader_(header)] = true;
  });

  var missing = Object.keys(STAFF_IMPORT_CONFIG.managementHeaders)
    .map(function (key) {
      return STAFF_IMPORT_CONFIG.managementHeaders[key];
    })
    .filter(function (header) {
      return !normalized[normalizeHeader_(header)];
    });

  if (missing.length === 0) return;
  sheet.getRange(1, lastColumn + 1, 1, missing.length).setValues([missing]);
  sheet.getRange(1, lastColumn + 1, 1, missing.length).setFontWeight('bold');
}

/**
 * @param {GoogleAppsScript.Spreadsheet.Spreadsheet} spreadsheet
 * @return {GoogleAppsScript.Spreadsheet.Sheet}
 */
function ensureNameMapSheet_(spreadsheet) {
  var sheet = spreadsheet.getSheetByName(STAFF_IMPORT_CONFIG.mapSheetName);
  if (sheet) return sheet;

  sheet = spreadsheet.insertSheet(STAFF_IMPORT_CONFIG.mapSheetName);
  var headers = Object.keys(STAFF_IMPORT_CONFIG.mapHeaders).map(function (key) {
    return STAFF_IMPORT_CONFIG.mapHeaders[key];
  });
  sheet.getRange(1, 1, 1, headers.length).setValues([headers]).setFontWeight('bold');
  sheet.getRange(2, 1, 1, headers.length).setValues([
    ['sample-one', 'Sample One', 'x', 'sample_user', false, '架空サンプル（無効）'],
  ]);
  sheet.getRange(2, 5, Math.max(sheet.getMaxRows() - 1, 1), 1).insertCheckboxes();
  sheet.setFrozenRows(1);
  return sheet;
}

/**
 * @return {GoogleAppsScript.Spreadsheet.Sheet}
 */
function getSourceSheet_() {
  var rawId = getImportDocumentProperties_().getProperty(
    STAFF_IMPORT_CONFIG.documentProperties.sourceSheetId,
  );
  if (!rawId) throw new Error('先に「初期セットアップ」を実行してください');

  var sheetId = Number(rawId);
  var sheet = SpreadsheetApp.getActive()
    .getSheets()
    .filter(function (candidate) {
      return candidate.getSheetId() === sheetId;
    })[0];
  if (!sheet) throw new Error('記録済みのフォーム回答シートが見つかりません');
  return sheet;
}

/**
 * @param {GoogleAppsScript.Spreadsheet.Sheet} sheet
 * @return {Array<Object<string, *>>}
 */
function readSourceRows_(sheet) {
  ensureManagementHeaders_(sheet);
  var lastRow = sheet.getLastRow();
  var lastColumn = sheet.getLastColumn();
  if (lastRow < 2) return [];

  var range = sheet.getRange(1, 1, lastRow, lastColumn);
  var rawValues = range.getValues();
  var displayValues = range.getDisplayValues();
  var richTextValues = range.getRichTextValues();
  var required = Object.assign({}, STAFF_IMPORT_CONFIG.sourceHeaders, STAFF_IMPORT_CONFIG.managementHeaders);
  var indexes = resolveHeaderIndexes_(displayValues[0], required);
  var rows = [];

  for (var offset = 1; offset < rawValues.length; offset += 1) {
    var raw = rawValues[offset];
    var display = displayValues[offset];
    var rich = richTextValues[offset];
    var row = {rowNumber: offset + 1, timestamp: raw[indexes.timestamp]};

    ['icon', 'x', 'bluesky', 'mixi2', 'medium', 'qiita', 'zenn', 'note', 'website', 'greeting'].forEach(
      function (key) {
        row[key] = effectiveCellText_(raw[indexes[key]], display[indexes[key]], rich[indexes[key]]);
      },
    );
    row.name = String(display[indexes.name] || '').trim();
    row.documentId = String(display[indexes.documentId] || '').trim();
    row.result = {
      importTarget: '',
      importStatus: '',
      importedAt: '',
      error: '',
    };
    rows.push(row);
  }
  return rows;
}

/**
 * @return {Array<Object<string, *>>}
 */
function readNameMapRows_() {
  var sheet = SpreadsheetApp.getActive().getSheetByName(STAFF_IMPORT_CONFIG.mapSheetName);
  if (!sheet) throw new Error('StaffNameMapシートがありません');
  if (sheet.getLastRow() < 2) return [];

  var values = sheet.getDataRange().getValues();
  var displayValues = sheet.getDataRange().getDisplayValues();
  var indexes = resolveHeaderIndexes_(displayValues[0], STAFF_IMPORT_CONFIG.mapHeaders);
  var rows = [];
  for (var offset = 1; offset < values.length; offset += 1) {
    var raw = values[offset];
    var display = displayValues[offset];
    if (display.every(function (value) { return String(value).trim() === ''; })) continue;
    rows.push({
      staffKey: display[indexes.staffKey],
      name: display[indexes.name],
      aliasType: display[indexes.aliasType],
      alias: display[indexes.alias],
      enabled: raw[indexes.enabled],
      note: display[indexes.note],
    });
  }
  return rows;
}

/**
 * @param {*} rawValue
 * @param {*} displayValue
 * @param {GoogleAppsScript.Spreadsheet.RichTextValue|null} richTextValue
 * @return {string}
 */
function effectiveCellText_(rawValue, displayValue, richTextValue) {
  if (richTextValue) {
    var directLink = richTextValue.getLinkUrl();
    if (directLink) return directLink;
    var runs = richTextValue.getRuns();
    for (var index = 0; index < runs.length; index += 1) {
      var runLink = runs[index].getLinkUrl();
      if (runLink) return runLink;
    }
  }
  var display = String(displayValue == null ? '' : displayValue).trim();
  if (display) return display;
  return String(rawValue == null ? '' : rawValue).trim();
}

/**
 * @param {GoogleAppsScript.Spreadsheet.Sheet} sheet
 * @param {Array<Object<string, *>>} rows
 */
function writeImportResults_(sheet, rows) {
  if (rows.length === 0) return;
  var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getDisplayValues()[0];
  var indexes = resolveHeaderIndexes_(headers, STAFF_IMPORT_CONFIG.managementHeaders);
  var rowCount = sheet.getLastRow() - 1;
  var byRowNumber = {};
  rows.forEach(function (row) {
    byRowNumber[row.rowNumber] = row;
  });

  Object.keys(STAFF_IMPORT_CONFIG.managementHeaders).forEach(function (key) {
    var range = sheet.getRange(2, indexes[key] + 1, rowCount, 1);
    var values = range.getValues();
    for (var offset = 0; offset < rowCount; offset += 1) {
      var row = byRowNumber[offset + 2];
      if (!row) continue;
      if (key === 'name') values[offset][0] = row.name || '';
      else if (key === 'documentId') values[offset][0] = row.documentId || '';
      else values[offset][0] = row.result[key] || '';
    }
    range.setValues(values);
  });
}
