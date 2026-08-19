/**
 * アバターのリサイズ・WebP 変換が実際に効くかを、Storage も Firestore も
 * 更新せずに確認する診断用スクリプト。
 *
 * Apps Script エディタから直接実行するため、関数名は末尾に _ を付けない
 * (_ 付きは private 扱いで実行対象に出てこない)。
 *
 * 回答シートから Drive ファイル ID を自動で拾うので、実際の ID をコードへ
 * 書き込む必要はない。ログにも氏名や SNS アカウントは出力しない。
 */
function checkStaffAvatarTransform() {
  var rows = readSourceRows_(getSourceSheet_());
  if (rows.length === 0) throw new Error('フォーム回答がありません');

  var checked = 0;
  for (var index = 0; index < rows.length && checked < STAFF_DIAGNOSTICS_SAMPLE_SIZE; index += 1) {
    var row = rows[index];
    try {
      extractDriveFileId_(row.icon);
    } catch (error) {
      continue; // アイコン未入力・不正な行は飛ばす
    }
    checked += 1;
    Logger.log('--- 行 ' + row.rowNumber + ' ---');
    reportAvatarTransform_(row);
  }

  if (checked === 0) Logger.log('Drive画像が入力された行がありません');
  Logger.log('--- 確認 ' + checked + ' 件。Storage / Firestore は更新していません ---');
}

/** 一度に確認する行数。 */
var STAFF_DIAGNOSTICS_SAMPLE_SIZE = 3;

/**
 * @param {Object<string, *>} row
 */
function reportAvatarTransform_(row) {
  try {
    var image = inspectDriveImage_(row.icon);
    var blob = loadStaffAvatarBlob_(image);
    var contentType = normalizeImageContentType_(blob.getContentType());
    var byteSize = blob.getBytes().length;
    Logger.log(
      '判定        : OK — strict WebP validation succeeded' +
        ' (contentType=' + contentType + ', byteSize=' + byteSize + ')',
    );
  } catch (error) {
    if (error && error.fatal === true) {
      Logger.log('判定        : ERROR_IMAGE — import would abort');
      throw error;
    }
    Logger.log('判定        : SKIPPED_IMAGE — import would skip this row');
  }
}
