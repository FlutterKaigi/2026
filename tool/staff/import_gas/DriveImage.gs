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
 * アップロード用のアバター画像を返す。
 *
 * Apps Script にはネイティブの画像リサイズも webp エンコードも無いため、
 * Drive のサムネイル生成に委譲して 320px 正方形の webp を取得する。
 * webp を取得できない場合は呼び出し側の画像エラー経路へ渡す。Drive API の
 * 認証・権限エラーは fatal を維持し、それ以外は行単位のスキップ対象にする。
 *
 * @param {{fileId: string, mimeType: string, file: GoogleAppsScript.Drive.File}} image
 * @return {GoogleAppsScript.Base.Blob}
 */
function loadStaffAvatarBlob_(image) {
  var thumbnailLink;
  try {
    thumbnailLink = fetchDriveThumbnailLink_(image.fileId);
  } catch (error) {
    throw sanitizeDriveThumbnailError_(error);
  }
  if (!thumbnailLink) throw new Error('Drive画像のWebPサムネイルを取得できません');

  var thumbnailUrl = buildDriveThumbnailUrl_(
    thumbnailLink,
    STAFF_IMPORT_CONFIG.avatarPixelSize,
  );
  var response;
  try {
    // thumbnailLink は署名付き URL のため、OAuth token は付与しない。
    response = UrlFetchApp.fetch(thumbnailUrl, {
      method: 'get',
      muteHttpExceptions: true,
      headers: {Accept: 'image/webp'},
    });
  } catch (error) {
    throw new Error('Drive画像のWebPサムネイルを取得できません');
  }

  var responseCode;
  try {
    responseCode = response.getResponseCode();
  } catch (error) {
    throw new Error('Drive画像のWebPサムネイルを取得できません');
  }
  if (responseCode !== 200) {
    throw new Error('Drive画像のWebPサムネイルを取得できません');
  }

  var blob;
  var contentType;
  try {
    blob = response.getBlob();
    contentType = normalizeImageContentType_(blob.getContentType());
  } catch (error) {
    throw new Error('Drive画像のWebPサムネイルを取得できません');
  }
  if (contentType !== 'image/webp') {
    throw new Error('Drive画像をWebPへ変換できません');
  }
  var bytes;
  try {
    bytes = blob.getBytes();
  } catch (error) {
    throw new Error('Drive画像のWebPサムネイルを取得できません');
  }
  if (!hasWebpSignature_(bytes)) {
    throw new Error('Drive画像をWebPへ変換できません');
  }
  return blob;
}

/**
 * @param {*} sourceError
 * @return {Error}
 */
function sanitizeDriveThumbnailError_(sourceError) {
  var sanitized = new Error('Drive画像のWebPサムネイルを取得できません');
  if (sourceError && sourceError.fatal === true) sanitized.fatal = true;
  if (sourceError && typeof sourceError.statusCode === 'number') {
    sanitized.statusCode = sourceError.statusCode;
  }
  return sanitized;
}

/**
 * @param {number[]} bytes
 * @return {boolean}
 */
function hasWebpSignature_(bytes) {
  return Boolean(
    bytes &&
      bytes.length >= 12 &&
      bytes[0] === 82 &&
      bytes[1] === 73 &&
      bytes[2] === 70 &&
      bytes[3] === 70 &&
      bytes[8] === 87 &&
      bytes[9] === 69 &&
      bytes[10] === 66 &&
      bytes[11] === 80,
  );
}

/**
 * Drive の thumbnailLink を取得する。短命な署名付き URL なので、アップロード
 * 直前に都度取得する。computeInputHash_ には含めない（含めると STG と本番で
 * 入力ハッシュが必ず食い違う）。
 *
 * @param {string} fileId
 * @return {string} 取得できない場合は空文字。
 */
function fetchDriveThumbnailLink_(fileId) {
  var response = fetchWithRetry_(
    'https://www.googleapis.com/drive/v3/files/' +
      encodeURIComponent(fileId) +
      '?fields=thumbnailLink&supportsAllDrives=true',
    {method: 'get'},
    [403, 404],
  );
  if (response.getResponseCode() !== 200) return '';
  return String(parseJsonResponse_(response).thumbnailLink || '');
}

/**
 * サムネイル URL に出力サイズと webp 要求を指定する。
 *
 * `s320-c-rw` は「長辺320・正方形クロップ・webp優先」。
 * 実際に webp が返るかは Drive 側の実装依存なので、呼び出し側で応答の
 * Content-Type を確認すること。
 *
 * @param {string} thumbnailLink
 * @param {number} size
 * @return {string}
 */
function buildDriveThumbnailUrl_(thumbnailLink, size) {
  var url = String(thumbnailLink || '').trim();
  if (!url) return '';
  // docs.google.com/feeds/vt 形式: sz クエリへ同じ変換オプションを指定する
  if (/[?&]sz=/i.test(url)) return url.replace(/([?&]sz=)[^&]*/i, '$1s' + size + '-c-rw');
  // lh3.googleusercontent.com 形式: 末尾のオプション列 (=s220 など) を差し替える
  if (/=[a-z0-9-]+$/i.test(url)) return url.replace(/=[a-z0-9-]+$/i, '=s' + size + '-c-rw');
  return url + '=s' + size + '-c-rw';
}

/**
 * @param {*} contentType
 * @return {string} 対応する画像 MIME type。判定できない場合は空文字。
 */
function normalizeImageContentType_(contentType) {
  var value = String(contentType || '').split(';')[0].trim().toLowerCase();
  return ['image/webp', 'image/png', 'image/jpeg'].indexOf(value) === -1 ? '' : value;
}
