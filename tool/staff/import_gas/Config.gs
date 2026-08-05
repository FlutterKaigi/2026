var STAFF_IMPORT_CONFIG = Object.freeze({
  transformVersion: '1',
  mapSheetName: 'StaffNameMap',
  maxImageBytes: 10 * 1024 * 1024,
  lockTimeoutMs: 1000,
  sourceHeaders: Object.freeze({
    timestamp: 'タイムスタンプ',
    icon: 'アイコン画像をアップロードしてください',
    x: 'X のアカウント名を記入してください。',
    bluesky: 'Bluesky のアカウント名を記入してください。',
    mixi2: 'mixi2 のアカウント名を記入してください。',
    medium: 'Mediumのアカウントを記入してください',
    qiita: 'Qiitaのアカウント名を記入してください。',
    zenn: 'Zennのアカウント名を記入してください。',
    note: 'noteのアカウント名を記入してください。',
    website: 'Webサイトに掲載したいURLを記入してください。',
    greeting: 'Webサイトに掲載したいワンフレーズを20文字以内でお願いします！',
  }),
  managementHeaders: Object.freeze({
    name: 'name',
    documentId: 'documentId',
    importTarget: 'importTarget',
    importStatus: 'importStatus',
    importedAt: 'importedAt',
    error: 'error',
  }),
  mapHeaders: Object.freeze({
    staffKey: 'staffKey',
    name: 'name',
    aliasType: 'aliasType',
    alias: 'alias',
    enabled: 'enabled',
    note: 'note',
  }),
  documentProperties: Object.freeze({
    sourceSheetId: 'STAFF_IMPORT_SOURCE_SHEET_ID',
    lastStgHash: 'STAFF_IMPORT_LAST_STG_SUCCESS_HASH',
    lastStgAt: 'STAFF_IMPORT_LAST_STG_SUCCESS_AT',
  }),
});

/**
 * @param {'STG'|'PROD'} target
 * @return {{target: string, projectId: string, bucket: string}}
 */
function getEnvironmentConfig_(target) {
  if (target !== 'STG' && target !== 'PROD') throw new Error('対象環境が不正です');

  var properties = PropertiesService.getScriptProperties();
  var projectId = String(properties.getProperty(target + '_FIREBASE_PROJECT_ID') || '').trim();
  var bucket = String(properties.getProperty(target + '_FIREBASE_STORAGE_BUCKET') || '').trim();

  if (!/^[a-z][a-z0-9-]{4,29}$/.test(projectId)) {
    throw new Error(target + '_FIREBASE_PROJECT_ID をScript Propertiesに設定してください');
  }
  if (!/^[a-z0-9][a-z0-9._-]+$/.test(bucket)) {
    throw new Error(target + '_FIREBASE_STORAGE_BUCKET をScript Propertiesに設定してください');
  }
  return {target: target, projectId: projectId, bucket: bucket};
}

/**
 * @return {GoogleAppsScript.Properties.Properties}
 */
function getImportDocumentProperties_() {
  var properties = PropertiesService.getDocumentProperties();
  if (!properties) throw new Error('コンテナバインド型GASとして実行してください');
  return properties;
}
