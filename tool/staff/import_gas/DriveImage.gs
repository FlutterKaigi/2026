/**
 * @param {*} value
 * @return {string}
 */
function extractDriveFileId_(value) {
  var text = String(value == null ? '' : value).trim();
  var queryMatch = /[?&]id=([A-Za-z0-9_-]{20,})/.exec(text);
  if (queryMatch) return queryMatch[1];

  var pathMatch = /\/file\/d\/([A-Za-z0-9_-]{20,})/.exec(text);
  if (pathMatch) return pathMatch[1];

  if (/^[A-Za-z0-9_-]{20,}$/.test(text)) return text;
  throw new Error('DriveファイルIDを抽出できません');
}

/**
 * @param {*} value
 * @return {{fileId: string, mimeType: string, size: number, lastUpdated: string, file: GoogleAppsScript.Drive.File}}
 */
function inspectDriveImage_(value) {
  var fileId = extractDriveFileId_(value);
  var file;
  try {
    file = DriveApp.getFileById(fileId);
  } catch (error) {
    throw new Error('Drive画像を参照できません');
  }

  var mimeType = file.getMimeType();
  var allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
  if (allowedMimeTypes.indexOf(mimeType) === -1) {
    throw new Error('対応していない画像形式です');
  }

  var size = file.getSize();
  if (size <= 0 || size > STAFF_IMPORT_CONFIG.maxImageBytes) {
    throw new Error('画像サイズは10MiB以下にしてください');
  }

  return {
    fileId: fileId,
    mimeType: mimeType,
    size: size,
    lastUpdated: file.getLastUpdated().toISOString(),
    file: file,
  };
}

/**
 * @param {{file: GoogleAppsScript.Drive.File, mimeType: string}} image
 * @return {GoogleAppsScript.Base.Blob}
 */
function loadDriveImageBlob_(image) {
  try {
    return image.file.getBlob().setContentType(image.mimeType);
  } catch (error) {
    throw new Error('Drive画像を読み込めません');
  }
}
