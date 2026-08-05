/**
 * @template T
 * @param {function(): T} operation
 * @param {function(T): boolean} shouldRetry
 * @param {function(number): void} sleep
 * @param {Array<number>} delays
 * @return {T}
 */
function runWithRetry_(operation, shouldRetry, sleep, delays) {
  var response = operation();
  for (var index = 0; index < delays.length && shouldRetry(response); index += 1) {
    sleep(delays[index]);
    response = operation();
  }
  return response;
}

/**
 * @param {string} url
 * @param {Object<string, *>} options
 * @param {Array<number>=} acceptedStatusCodes
 * @return {GoogleAppsScript.URL_Fetch.HTTPResponse}
 */
function fetchWithRetry_(url, options, acceptedStatusCodes) {
  var requestOptions = Object.assign({}, options || {});
  requestOptions.headers = Object.assign({}, requestOptions.headers || {}, {
    Authorization: 'Bearer ' + ScriptApp.getOAuthToken(),
  });
  requestOptions.muteHttpExceptions = true;

  var response = runWithRetry_(
    function () {
      return UrlFetchApp.fetch(url, requestOptions);
    },
    function (candidate) {
      var code = candidate.getResponseCode();
      return code === 429 || code >= 500;
    },
    function (milliseconds) {
      Utilities.sleep(milliseconds);
    },
    [1000, 2000, 4000],
  );

  var statusCode = response.getResponseCode();
  var accepted = statusCode >= 200 && statusCode < 300;
  if (!accepted && (acceptedStatusCodes || []).indexOf(statusCode) !== -1) return response;
  if (accepted) return response;

  var method = String(requestOptions.method || 'get').toUpperCase();
  var endpoint = String(url).split(/[?#]/)[0].replace(/^https?:\/\//i, '');
  var detail = formatGoogleApiErrorDetail_(response.getContentText());
  var message =
    'Google API request failed (HTTP ' + statusCode + ') ' + method + ' ' + endpoint;
  if (detail) message += ': ' + detail;

  var error = new Error(message);
  if (statusCode === 401 || statusCode === 403) error.fatal = true;
  error.statusCode = statusCode;
  throw error;
}

/**
 * @param {string} body
 * @return {string}
 */
function formatGoogleApiErrorDetail_(body) {
  var normalized = normalizeHttpErrorText_(body);
  if (!normalized) return '';

  try {
    var parsed = JSON.parse(body);
    var apiError = parsed && parsed.error;
    if (!apiError || typeof apiError !== 'object') return '';

    var parts = [];
    if (apiError.message) parts.push(normalizeHttpErrorText_(apiError.message));
    if (apiError.status) parts.push('status=' + normalizeHttpErrorText_(apiError.status));

    var firstError = apiError.errors && apiError.errors[0];
    if (firstError && firstError.reason) {
      parts.push('reason=' + normalizeHttpErrorText_(firstError.reason));
    }
    return truncateHttpErrorText_(parts.join('; '), 300);
  } catch (parseError) {
    return truncateHttpErrorText_(normalized, 300);
  }
}

/**
 * @param {*} value
 * @return {string}
 */
function normalizeHttpErrorText_(value) {
  return String(value || '').replace(/\s+/g, ' ').replace(/^\s+|\s+$/g, '');
}

/**
 * @param {string} value
 * @param {number} maxLength
 * @return {string}
 */
function truncateHttpErrorText_(value, maxLength) {
  if (value.length <= maxLength) return value;
  return value.substring(0, maxLength - 3) + '...';
}

/**
 * @param {GoogleAppsScript.URL_Fetch.HTTPResponse} response
 * @return {Object<string, *>}
 */
function parseJsonResponse_(response) {
  var body = response.getContentText();
  return body ? JSON.parse(body) : {};
}
