/**
 * Removes characters that should not affect account-name matching.
 *
 * @param {string} aliasType
 * @param {*} value
 * @return {string}
 */
function normalizeAlias_(aliasType, value) {
  var normalized = String(value == null ? '' : value)
    .trim()
    .normalize('NFKC')
    .replace(/[\u200B-\u200D\uFEFF]/g, '');

  normalized = extractAliasFromProfileUrl_(aliasType, normalized);
  return normalized.replace(/^@+/, '').toLowerCase();
}

/**
 * @param {string} aliasType
 * @param {string} value
 * @return {string}
 */
function extractAliasFromProfileUrl_(aliasType, value) {
  var parsed = parseHttpUrl_(value);
  if (!parsed) return value;

  var segments = parsed.path.split('/').filter(function (segment) {
    return segment !== '';
  });

  if (aliasType === 'x' && (parsed.host === 'x.com' || parsed.host === 'twitter.com')) {
    return segments[0] || value;
  }
  if (aliasType === 'bluesky' && parsed.host === 'bsky.app' && segments[0] === 'profile') {
    return segments[1] || value;
  }
  if (aliasType === 'mixi2' && parsed.host === 'mixi.social') {
    return (segments[0] || value).replace(/^@/, '');
  }
  if (aliasType === 'medium' && parsed.host === 'medium.com') {
    return (segments[0] || value).replace(/^@/, '');
  }
  if (aliasType === 'qiita' && parsed.host === 'qiita.com') {
    return segments[0] || value;
  }
  if (aliasType === 'zenn' && parsed.host === 'zenn.dev') {
    return segments[0] || value;
  }
  if (aliasType === 'note' && parsed.host === 'note.com') {
    return segments[0] || value;
  }
  return value;
}

/**
 * Parses the HTTP URL subset needed by the importer without relying on the
 * browser-only URL class.
 *
 * @param {string} value
 * @return {{scheme: string, host: string, path: string, query: string, hash: string}|null}
 */
function parseHttpUrl_(value) {
  var match = /^(https?):\/\/([^/?#]+)([^?#]*)(\?[^#]*)?(#.*)?$/i.exec(value);
  if (!match) return null;

  var host = match[2].replace(/^[^@]+@/, '').replace(/:\d+$/, '').toLowerCase();
  return {
    scheme: match[1].toLowerCase(),
    host: host,
    path: match[3] || '/',
    query: match[4] || '',
    hash: match[5] || '',
  };
}

/**
 * @param {Object<string, *>} values
 * @return {Array<{type: string, value: string}>}
 */
function buildSnsLinks_(values) {
  var order = ['x', 'bluesky', 'mixi2', 'medium', 'qiita', 'zenn', 'note', 'website'];
  var links = [];
  var seen = {};

  order.forEach(function (column) {
    var link = buildSocialLink_(column, values[column]);
    if (!link) return;

    var dedupeKey = link.value.toLowerCase();
    if (seen[dedupeKey]) return;
    seen[dedupeKey] = true;
    links.push(link);
  });

  return links;
}

/**
 * @param {string} column
 * @param {*} rawValue
 * @return {{type: string, value: string}|null}
 */
function buildSocialLink_(column, rawValue) {
  var value = cleanCellText_(rawValue);
  if (!value) return null;

  var explicitUrl = extractFirstUrl_(value);
  if (explicitUrl) {
    var canonical = canonicalizeHttpUrl_(explicitUrl);
    return {type: inferLinkType_(canonical.host), value: canonical.value};
  }

  if (/^[a-z][a-z0-9+.-]*:\/\//i.test(value)) {
    throw new Error('http/https 以外のURLは使用できません');
  }

  if (column === 'website') {
    if (!looksLikeDomain_(value)) throw new Error('URLが不正です');
    var website = canonicalizeHttpUrl_('https://' + value);
    return {type: inferLinkType_(website.host), value: website.value};
  }

  if (column === 'medium' && looksLikeDomain_(value)) {
    var mediumWebsite = canonicalizeHttpUrl_('https://' + value);
    return {type: inferLinkType_(mediumWebsite.host), value: mediumWebsite.value};
  }

  var handle = value.replace(/^@+/, '').trim();
  if (!handle || /\s/.test(handle)) {
    throw new Error(column + ' のアカウント名が不正です');
  }

  var builders = {
    x: function (account) {
      return 'https://x.com/' + encodeURIComponent(account);
    },
    bluesky: function (account) {
      return 'https://bsky.app/profile/' + encodeURIComponent(account);
    },
    mixi2: function (account) {
      return 'https://mixi.social/@' + encodeURIComponent(account);
    },
    medium: function (account) {
      return 'https://medium.com/@' + encodeURIComponent(account);
    },
    qiita: function (account) {
      return 'https://qiita.com/' + encodeURIComponent(account);
    },
    zenn: function (account) {
      return 'https://zenn.dev/' + encodeURIComponent(account);
    },
    note: function (account) {
      return 'https://note.com/' + encodeURIComponent(account);
    },
  };

  if (!builders[column]) throw new Error('未対応のSNS列です: ' + column);
  return {type: column, value: builders[column](handle)};
}

/**
 * @param {*} value
 * @return {string}
 */
function cleanCellText_(value) {
  return String(value == null ? '' : value)
    .trim()
    .normalize('NFKC')
    .replace(/[\u200B-\u200D\uFEFF]/g, '');
}

/**
 * @param {string} value
 * @return {string|null}
 */
function extractFirstUrl_(value) {
  var match = /https?:\/\/[^\s\]\[()（）<>「」]+/i.exec(value);
  if (!match) return null;
  return match[0].replace(/[.,、。!?！？]+$/, '');
}

/**
 * @param {string} value
 * @return {{host: string, value: string}}
 */
function canonicalizeHttpUrl_(value) {
  var parsed = parseHttpUrl_(value);
  if (!parsed) throw new Error('URLが不正です');

  var path = parsed.path || '/';
  if (path === '/' && !parsed.query && !parsed.hash) path = '';
  return {
    host: parsed.host,
    value: parsed.scheme + '://' + parsed.host + path + parsed.query + parsed.hash,
  };
}

/**
 * @param {string} value
 * @return {boolean}
 */
function looksLikeDomain_(value) {
  return /^[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?\.[a-z]{2,}(?:[/:?#].*)?$/i.test(value);
}

/**
 * @param {string} host
 * @return {string}
 */
function inferLinkType_(host) {
  var normalizedHost = host.replace(/^www\./, '');
  if (normalizedHost === 'x.com' || normalizedHost === 'twitter.com') return 'x';
  if (normalizedHost === 'bsky.app') return 'bluesky';
  if (normalizedHost === 'mixi.social') return 'mixi2';
  if (normalizedHost === 'medium.com' || /\.medium\.com$/.test(normalizedHost)) return 'medium';
  if (normalizedHost === 'qiita.com') return 'qiita';
  if (normalizedHost === 'zenn.dev') return 'zenn';
  if (normalizedHost === 'note.com') return 'note';
  if (normalizedHost === 'github.com') return 'github';
  return 'web';
}

/**
 * @param {Array<Object<string, *>>} rows
 * @return {{byAlias: Object<string, string>, byStaffKey: Object<string, {staffKey: string, name: string}>}}
 */
function buildNameMapIndex_(rows) {
  var aliasTypes = ['x', 'bluesky', 'mixi2', 'medium', 'qiita', 'zenn', 'note'];
  var byAlias = {};
  var byStaffKey = {};

  rows.forEach(function (row, index) {
    if (!isEnabled_(row.enabled)) return;

    var staffKey = cleanCellText_(row.staffKey);
    var name = cleanCellText_(row.name);
    var aliasType = cleanCellText_(row.aliasType).toLowerCase();
    var alias = normalizeAlias_(aliasType, row.alias);
    var rowNumber = index + 2;

    if (!/^[a-z0-9][a-z0-9-]{1,62}$/.test(staffKey)) {
      throw new Error('StaffNameMap ' + rowNumber + '行目: staffKeyが不正です');
    }
    if (!name) throw new Error('StaffNameMap ' + rowNumber + '行目: nameが空です');
    if (aliasTypes.indexOf(aliasType) === -1) {
      throw new Error('StaffNameMap ' + rowNumber + '行目: aliasTypeが不正です');
    }
    if (!alias) throw new Error('StaffNameMap ' + rowNumber + '行目: aliasが空です');

    if (byStaffKey[staffKey] && byStaffKey[staffKey].name !== name) {
      throw new Error('StaffNameMap: 同じstaffKeyに異なるnameが設定されています');
    }
    byStaffKey[staffKey] = {staffKey: staffKey, name: name};

    var key = aliasLookupKey_(aliasType, alias);
    if (byAlias[key] && byAlias[key] !== staffKey) {
      throw new Error('StaffNameMap: 同じ別名が複数のstaffKeyを指しています');
    }
    byAlias[key] = staffKey;
  });

  return {byAlias: byAlias, byStaffKey: byStaffKey};
}

/**
 * @param {Object<string, *>} row
 * @param {{byAlias: Object<string, string>, byStaffKey: Object<string, {staffKey: string, name: string}>}} index
 * @return {{staffKey: string, name: string}|null}
 */
function resolveStaff_(row, index) {
  var aliasTypes = ['x', 'bluesky', 'mixi2', 'medium', 'qiita', 'zenn', 'note'];
  var matchedStaffKeys = {};

  aliasTypes.forEach(function (aliasType) {
    var alias = normalizeAlias_(aliasType, row[aliasType]);
    if (!alias) return;
    var staffKey = index.byAlias[aliasLookupKey_(aliasType, alias)];
    if (staffKey) matchedStaffKeys[staffKey] = true;
  });

  var keys = Object.keys(matchedStaffKeys);
  if (keys.length > 1) throw new Error('複数のスタッフ候補に一致しました');
  if (keys.length === 1) return index.byStaffKey[keys[0]];

  var documentMatch = /^staff-([a-z0-9][a-z0-9-]{1,62})$/.exec(cleanCellText_(row.documentId));
  if (documentMatch && index.byStaffKey[documentMatch[1]]) {
    return index.byStaffKey[documentMatch[1]];
  }
  return null;
}

/**
 * @param {string} aliasType
 * @param {string} alias
 * @return {string}
 */
function aliasLookupKey_(aliasType, alias) {
  return aliasType + ':' + normalizeAlias_(aliasType, alias);
}

/**
 * @param {*} value
 * @return {boolean}
 */
function isEnabled_(value) {
  return value === true || String(value).trim().toLowerCase() === 'true';
}

/**
 * @param {Array<Object<string, *>>} rows
 * @return {{selected: Array<Object<string, *>>, duplicates: Array<Object<string, *>>}}
 */
function selectLatestRows_(rows) {
  var latestByStaffKey = {};

  rows.forEach(function (row) {
    var timestamp = row.timestamp instanceof Date ? row.timestamp.getTime() : NaN;
    if (!Number.isFinite(timestamp)) throw new Error(row.rowNumber + '行目: タイムスタンプが不正です');

    var current = latestByStaffKey[row.staffKey];
    if (!current) {
      latestByStaffKey[row.staffKey] = row;
      return;
    }

    var currentTime = current.timestamp.getTime();
    if (timestamp > currentTime || (timestamp === currentTime && row.rowNumber > current.rowNumber)) {
      latestByStaffKey[row.staffKey] = row;
    }
  });

  var selected = [];
  var duplicates = [];
  rows.forEach(function (row) {
    if (latestByStaffKey[row.staffKey] === row) selected.push(row);
    else duplicates.push(row);
  });
  selected.sort(function (a, b) {
    return a.rowNumber - b.rowNumber;
  });
  duplicates.sort(function (a, b) {
    return a.rowNumber - b.rowNumber;
  });
  return {selected: selected, duplicates: duplicates};
}

/**
 * @param {Array<Object<string, *>>} rows
 * @return {Array<Object<string, *>>}
 */
function assignOrders_(rows) {
  return rows
    .slice()
    .sort(function (a, b) {
      return a.rowNumber - b.rowNumber;
    })
    .map(function (row, index) {
      row.order = index + 1;
      return row;
    });
}

/**
 * @param {*} value
 * @return {string}
 */
function stableStringify_(value) {
  if (value === null || typeof value !== 'object') return JSON.stringify(value);
  if (value instanceof Date) return JSON.stringify(value.toISOString());
  if (Array.isArray(value)) {
    return '[' + value.map(stableStringify_).join(',') + ']';
  }

  return (
    '{' +
    Object.keys(value)
      .sort()
      .map(function (key) {
        return JSON.stringify(key) + ':' + stableStringify_(value[key]);
      })
      .join(',') +
    '}'
  );
}

/**
 * @param {*} value
 * @return {number}
 */
function countCodePoints_(value) {
  return Array.from(String(value == null ? '' : value)).length;
}
