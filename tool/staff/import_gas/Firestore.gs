/**
 * @param {string} projectId
 * @param {string} documentId
 * @param {Object<string, *>} data
 * @param {{updateTime: string}|null} existingDocument
 * @return {{url: string, body: Object<string, *>}}
 */
function buildFirestoreCommit_(projectId, documentId, data, existingDocument) {
  var database = 'projects/' + projectId + '/databases/(default)';
  var fields = {};
  Object.keys(data).forEach(function (key) {
    fields[key] = toFirestoreValue_(data[key]);
  });

  var write = {
    update: {
      name: database + '/documents/staffMembers/' + documentId,
      fields: fields,
    },
  };

  if (existingDocument) {
    if (!existingDocument.updateTime) throw new Error('既存ドキュメントのupdateTimeがありません');
    write.updateMask = {fieldPaths: Object.keys(data)};
    write.updateTransforms = [{fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME'}];
    write.currentDocument = {updateTime: existingDocument.updateTime};
  } else {
    write.updateTransforms = [
      {fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME'},
      {fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME'},
    ];
    write.currentDocument = {exists: false};
  }

  return {
    url: 'https://firestore.googleapis.com/v1/' + database + '/documents:commit',
    body: {writes: [write]},
  };
}

/**
 * @param {*} value
 * @return {Object<string, *>}
 */
function toFirestoreValue_(value) {
  if (value === null) return {nullValue: null};
  if (typeof value === 'string') return {stringValue: value};
  if (typeof value === 'boolean') return {booleanValue: value};
  if (typeof value === 'number' && Number.isInteger(value)) return {integerValue: String(value)};
  if (typeof value === 'number') return {doubleValue: value};
  if (value instanceof Date) return {timestampValue: value.toISOString()};
  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value.map(toFirestoreValue_),
      },
    };
  }
  if (typeof value === 'object') {
    var fields = {};
    Object.keys(value).forEach(function (key) {
      fields[key] = toFirestoreValue_(value[key]);
    });
    return {mapValue: {fields: fields}};
  }
  throw new Error('Firestoreへ変換できない値です');
}

/**
 * @param {{projectId: string}} environment
 * @param {string} documentId
 * @return {Object<string, *>|null}
 */
function getStaffDocument_(environment, documentId) {
  var url =
    'https://firestore.googleapis.com/v1/projects/' +
    encodeURIComponent(environment.projectId) +
    '/databases/(default)/documents/staffMembers/' +
    encodeURIComponent(documentId);
  var response = fetchWithRetry_(url, {method: 'get'}, [404]);
  if (response.getResponseCode() === 404) return null;
  return parseJsonResponse_(response);
}

/**
 * @param {{projectId: string}} environment
 * @param {string} documentId
 * @param {Object<string, *>} data
 * @return {Object<string, *>}
 */
function upsertStaffDocument_(environment, documentId, data) {
  var existing = getStaffDocument_(environment, documentId);
  var request = buildFirestoreCommit_(environment.projectId, documentId, data, existing);
  var response = fetchWithRetry_(request.url, {
    method: 'post',
    contentType: 'application/json',
    payload: JSON.stringify(request.body),
  });
  return parseJsonResponse_(response);
}
