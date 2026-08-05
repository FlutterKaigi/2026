/**
 * @param {string} bucket
 * @param {string} objectPath
 * @param {string} token
 * @return {string}
 */
function buildFirebaseDownloadUrl_(bucket, objectPath, token) {
  return (
    'https://firebasestorage.googleapis.com/v0/b/' +
    encodeURIComponent(bucket) +
    '/o/' +
    encodeURIComponent(objectPath) +
    '?alt=media&token=' +
    encodeURIComponent(token)
  );
}

/**
 * @param {{bucket: string}} environment
 * @param {string} staffKey
 * @param {{mimeType: string}} image
 * @param {GoogleAppsScript.Base.Blob} blob
 * @return {string}
 */
function uploadStaffAvatar_(environment, staffKey, image, blob) {
  var objectPath = 'public/staff/' + staffKey + '/avatar';
  var existing = getStorageObjectMetadata_(environment.bucket, objectPath);
  var existingTokens = existing && existing.metadata
    ? String(existing.metadata.firebaseStorageDownloadTokens || '')
    : '';
  var token = existingTokens.split(',')[0].trim() || Utilities.getUuid();
  var generationCondition = existing ? existing.generation : '0';
  var boundary = 'staff_avatar_' + Utilities.getUuid().replace(/-/g, '');
  var multipartPayload = buildStorageMultipartPayload_(
    boundary,
    {
      name: objectPath,
      contentType: image.mimeType,
      cacheControl: 'public,max-age=3600',
      metadata: {firebaseStorageDownloadTokens: token},
    },
    image.mimeType,
    blob.getBytes(),
  );

  var uploadUrl =
    'https://storage.googleapis.com/upload/storage/v1/b/' +
    encodeURIComponent(environment.bucket) +
    '/o?uploadType=multipart&ifGenerationMatch=' +
    encodeURIComponent(generationCondition);
  fetchWithRetry_(uploadUrl, {
    method: 'post',
    contentType: 'multipart/related; boundary=' + boundary,
    payload: multipartPayload,
  });

  return buildFirebaseDownloadUrl_(environment.bucket, objectPath, token);
}

/**
 * @param {string} boundary
 * @param {Object<string, *>} metadata
 * @param {string} mimeType
 * @param {number[]} imageBytes
 * @return {number[]}
 */
function buildStorageMultipartPayload_(boundary, metadata, mimeType, imageBytes) {
  var payload = [];
  appendStorageBytes_(
    payload,
    Utilities.newBlob(
      '--' +
        boundary +
        '\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n' +
        JSON.stringify(metadata) +
        '\r\n--' +
        boundary +
        '\r\nContent-Type: ' +
        mimeType +
        '\r\n\r\n',
    ).getBytes(),
  );
  appendStorageBytes_(payload, imageBytes);
  appendStorageBytes_(
    payload,
    Utilities.newBlob('\r\n--' + boundary + '--\r\n').getBytes(),
  );
  return payload;
}

/**
 * @param {number[]} target
 * @param {number[]} source
 */
function appendStorageBytes_(target, source) {
  for (var index = 0; index < source.length; index += 1) {
    target.push(source[index]);
  }
}

/**
 * @param {string} bucket
 * @param {string} objectPath
 * @return {Object<string, *>|null}
 */
function getStorageObjectMetadata_(bucket, objectPath) {
  var response = fetchWithRetry_(
    storageObjectUrl_(bucket, objectPath) + '?fields=generation,metageneration,metadata',
    {method: 'get'},
    [404],
  );
  if (response.getResponseCode() === 404) return null;
  return parseJsonResponse_(response);
}

/**
 * @param {string} bucket
 * @param {string} objectPath
 * @return {string}
 */
function storageObjectUrl_(bucket, objectPath) {
  return (
    'https://storage.googleapis.com/storage/v1/b/' +
    encodeURIComponent(bucket) +
    '/o/' +
    encodeURIComponent(objectPath)
  );
}
