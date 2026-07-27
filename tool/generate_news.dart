/// Generates `apps/website/lib/constants/generated_news.dart` from the `news`
/// Firestore collection managed by `packages/data` (the same data the admin
/// dashboard writes), or a local sample fixture as a fallback.
///
/// Fetching and decoding reuses `packages/data`'s `News` / `LocaleMap`
/// domain model directly (`News.fromJson`, imported via the Flutter-free
/// `package:data/news_model.dart`), the same model class the app and
/// dashboard use — this script does not maintain its own shadow copy of the
/// `news` document shape. It does *not* use `FirestoreNewsRepository`
/// (`package:data/news.dart`), which needs `cloud_firestore`'s platform
/// channels and a running Firebase app — both unavailable, and uncompilable,
/// in a bare `dart run` script; Firestore access still goes through the REST
/// API below.
///
/// Unlike `tool/generate_sponsors.dart`, the output here is **not**
/// git-ignored: news items are not sensitive, so the generated file is
/// checked into git like any other source file. Re-run this script whenever
/// the news list should be refreshed; CI also re-runs it before every
/// website build/deploy so the live site always reflects the latest data,
/// with the committed copy acting as an offline/preview fallback.
///
/// Run via:
///
/// ```sh
/// # Local: reads the Firestore emulator (start it + seed first, e.g.
/// #   fvm dart run melos firebase:start  /  fvm dart run melos firebase:seed)
/// fvm dart run melos news:generate
///
/// # STG / prod: point at the real project over HTTPS.
/// FIREBASE_PROJECT_ID=flutterkaigi-2026-stg \
///   FIRESTORE_HOST=firestore.googleapis.com \
///   FIRESTORE_ACCESS_TOKEN=$(gcloud auth print-access-token) \
///   fvm dart run tool/generate_news.dart
/// ```
///
/// Data source (Firestore REST API, mirroring `tool/firebase_seed.dart`):
///   - `FIREBASE_PROJECT_ID`     — defaults to `dev-flutterkaigi-2026`.
///   - `FIRESTORE_EMULATOR_HOST` — when set (or the host is localhost), talk to
///     the emulator over HTTP with the `owner` bearer token.
///   - `FIRESTORE_HOST`          — explicit host for a real project (HTTPS).
///   - `FIRESTORE_ACCESS_TOKEN`  — OAuth bearer token for a real project.
///   - `FIRESTORE_API_KEY`       — optional `?key=` for a real project.
///   - If Firestore is unreachable, fall back to `tool/news/sample_news.json`
///     so offline/preview builds still render something. A *reachable but
///     empty* collection yields an empty News card (no fake data).
library;

import 'dart:convert';
import 'dart:io';

import 'package:data/news_model.dart';
import 'package:http/http.dart' as http;

const _outFile = 'apps/website/lib/constants/generated_news.dart';
const _sampleFile = 'tool/news/sample_news.json';

// Firestore defaults — kept in sync with tool/firebase_seed.dart.
const _defaultProjectId = 'dev-flutterkaigi-2026';
const _defaultFirestoreHost = 'localhost:8080';

Future<void> main(List<String> args) async {
  final entries = await _loadNews();
  if (entries.isEmpty) {
    stderr.writeln('warning: no news found in the data source.');
  }

  _writeDart(entries);
  _format(_outFile);

  stdout.writeln('Wrote $_outFile with ${entries.length} news item(s).');
}

// ── Data loading ──────────────────────────────────────────────────────────

Future<List<News>> _loadNews() async {
  try {
    final news = await _fetchFirestoreNews();
    stdout.writeln('Loaded ${news.length} news item(s) from Firestore.');
    // A reachable but empty collection is a valid state — emit an empty list
    // rather than masking it with fake placeholders.
    return _sortByPublishedAtDesc(news);
  } catch (e) {
    stderr.writeln(
      'warning: could not load news from Firestore ($e).\n'
      'Falling back to $_sampleFile.',
    );
    return _sortByPublishedAtDesc(_loadSampleNews());
  }
}

/// Fetches every document in the `news` collection via the Firestore REST
/// API and decodes each into `packages/data`'s [News] model.
///
/// Talks to the local emulator by default; set the `FIRESTORE_*` /
/// `FIREBASE_PROJECT_ID` env vars (see the library doc) to target STG/prod.
Future<List<News>> _fetchFirestoreNews() async {
  final projectId = Platform.environment['FIREBASE_PROJECT_ID'] ?? _defaultProjectId;
  final emulatorHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  final host = _normalizeHost(
    Platform.environment['FIRESTORE_HOST'] ?? emulatorHost ?? _defaultFirestoreHost,
  );
  final isEmulator = emulatorHost != null || host.startsWith('localhost') || host.startsWith('127.0.0.1');
  final scheme = isEmulator ? 'http' : 'https';
  final token = Platform.environment['FIRESTORE_ACCESS_TOKEN'];
  final apiKey = Platform.environment['FIRESTORE_API_KEY'];

  stdout.writeln(
    'Fetching news from Firestore '
    '($scheme://$host, project $projectId${isEmulator ? ', emulator' : ''}).',
  );

  final headers = <String, String>{
    'Accept': 'application/json',
    if (isEmulator)
      'Authorization': 'Bearer owner'
    else if (token != null && token.isNotEmpty)
      'Authorization': 'Bearer $token',
  };

  final base =
      '$scheme://$host/v1/projects/${Uri.encodeComponent(projectId)}'
      '/databases/(default)/documents/news';

  final news = <News>[];
  String? pageToken;
  do {
    final query = <String>[
      'pageSize=300',
      if (pageToken != null && pageToken.isNotEmpty) 'pageToken=${Uri.encodeComponent(pageToken)}',
      if (apiKey != null && apiKey.isNotEmpty) 'key=${Uri.encodeComponent(apiKey)}',
    ];
    final uri = Uri.parse('$base?${query.join('&')}');
    final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200) {
      throw HttpException('Firestore returned ${resp.statusCode}: ${resp.body}');
    }
    final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final docs = (decoded['documents'] as List?) ?? const [];
    for (final doc in docs.whereType<Map<String, dynamic>>()) {
      news.add(News.fromJson(_decodeFirestoreDoc(doc)));
    }
    pageToken = decoded['nextPageToken'] as String?;
  } while (pageToken != null && pageToken.isNotEmpty);

  return news;
}

List<News> _loadSampleNews() {
  final decoded = jsonDecode(File(_sampleFile).readAsStringSync());
  return _extractList(decoded).map(News.fromJson).toList();
}

/// Accepts a bare array or a `{news|data|items: [...]}` envelope.
List<Map<String, dynamic>> _extractList(Object? decoded) {
  final list = switch (decoded) {
    final List<dynamic> l => l,
    {'news': final List<dynamic> l} => l,
    {'data': final List<dynamic> l} => l,
    {'items': final List<dynamic> l} => l,
    _ => const <dynamic>[],
  };
  return list.whereType<Map<String, dynamic>>().toList();
}

List<News> _sortByPublishedAtDesc(List<News> news) => [...news]..sort(
  (a, b) => b.publishedAt.compareTo(a.publishedAt),
);

String _normalizeHost(String host) {
  var value = host.trim().replaceFirst(RegExp(r'^https?://'), '');
  while (value.endsWith('/')) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}

// ── Firestore REST decoding (inverse of tool/firebase_seed.dart) ────────────

/// Decodes a Firestore REST document (`{name, fields, ...}`) into a plain map
/// of the `packages/data` `News` model, injecting the doc id.
Map<String, dynamic> _decodeFirestoreDoc(Map<String, dynamic> doc) {
  final name = (doc['name'] ?? '').toString();
  final id = name.contains('/') ? name.split('/').last : name;
  final fields = (doc['fields'] as Map?)?.cast<String, dynamic>() ?? const {};
  return {
    for (final e in fields.entries) e.key: _decodeFirestoreValue(e.value),
    'id': id,
  };
}

/// Inverse of `_encodeFirestoreValue` in `tool/firebase_seed.dart`.
Object? _decodeFirestoreValue(Object? value) {
  final m = (value as Map?)?.cast<String, dynamic>();
  if (m == null) return null;
  if (m.containsKey('nullValue')) return null;
  if (m.containsKey('booleanValue')) return m['booleanValue'];
  if (m.containsKey('integerValue')) {
    return int.tryParse(m['integerValue'].toString());
  }
  if (m.containsKey('doubleValue')) return m['doubleValue'];
  if (m.containsKey('timestampValue')) return m['timestampValue'];
  if (m.containsKey('stringValue')) return m['stringValue'];
  if (m.containsKey('referenceValue')) return m['referenceValue'];
  if (m.containsKey('mapValue')) {
    final fields = ((m['mapValue'] as Map?)?['fields'] as Map?)?.cast<String, dynamic>() ?? const {};
    return {
      for (final e in fields.entries) e.key: _decodeFirestoreValue(e.value),
    };
  }
  if (m.containsKey('arrayValue')) {
    final values = ((m['arrayValue'] as Map?)?['values'] as List?) ?? const [];
    return values.map(_decodeFirestoreValue).toList();
  }
  return null;
}

// ── Dart emission ───────────────────────────────────────────────────────────

void _writeDart(List<News> news) {
  final out = StringBuffer()
    ..writeln('// GENERATED FILE — do not edit by hand.')
    ..writeln('// Source of truth: the `news` Firestore collection (packages/data),')
    ..writeln('// or tool/news/sample_news.json when Firestore is unreachable.')
    ..writeln('// Regenerate via: fvm dart run melos news:generate')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars, directives_ordering')
    ..writeln()
    ..writeln("import 'news_links.dart';")
    ..writeln()
    // Not `const`: NewsEntry carries a DateTime field, and DateTime has no
    // const constructor (DateTime.utc(...) is a regular factory call).
    ..writeln('final List<NewsEntry> generatedNews = [');

  for (final n in news) {
    // Fall back across locales so a news item with only one language still
    // renders something on both site locales (LocaleMap itself doesn't do
    // this — both fields are just required strings).
    final titleJa = _firstNonEmpty([n.title.ja, n.title.en]);
    final titleEn = _firstNonEmpty([n.title.en, n.title.ja]);
    final urlJa = _firstNonEmpty([n.url.ja, n.url.en]);
    final urlEn = _firstNonEmpty([n.url.en, n.url.ja]);
    out
      ..writeln('  NewsEntry(')
      ..writeln('    id: ${_str(n.id)},')
      ..writeln('    titleJa: ${_str(titleJa)},')
      ..writeln('    titleEn: ${_str(titleEn)},')
      ..writeln('    urlJa: ${_str(urlJa)},')
      ..writeln('    urlEn: ${_str(urlEn)},')
      ..writeln('    publishedAt: ${_dateTime(n.publishedAt)},')
      ..writeln('  ),');
  }

  out.writeln('];');
  File(_outFile).writeAsStringSync(out.toString());
}

void _format(String path) {
  // Format with whatever is available; never fail the build over formatting.
  // Try `dart` first (present in CI), then `fvm dart` (local fvm setups).
  // `Process.runSync` throws (not just non-zero) when the executable is
  // missing, so each candidate is guarded.
  const candidates = [
    ['dart', 'format'],
    ['fvm', 'dart', 'format'],
  ];
  for (final cmd in candidates) {
    try {
      final r = Process.runSync(cmd.first, [...cmd.skip(1), path]);
      if (r.exitCode == 0) return;
    } on ProcessException {
      // Executable not found — try the next candidate.
    }
  }
  stderr.writeln('warning: could not run `dart format` on $path; left unformatted.');
}

/// Single-quoted Dart string literal with the necessary escapes. Non-ASCII is
/// emitted verbatim (Dart source is UTF-8).
String _str(String s) {
  final b = StringBuffer("'");
  for (final r in s.runes) {
    switch (r) {
      case 0x5c: // backslash
        b.write(r'\\');
      case 0x27: // single quote
        b.write(r"\'");
      case 0x24: // dollar
        b.write(r'\$');
      case 0x0a:
        b.write(r'\n');
      case 0x0d:
        b.write(r'\r');
      case 0x09:
        b.write(r'\t');
      default:
        b.writeCharCode(r);
    }
  }
  b.write("'");
  return b.toString();
}

/// Emits a UTC `DateTime.utc(...)` literal for [dt].
String _dateTime(DateTime dt) {
  final u = dt.toUtc();
  return 'DateTime.utc(${u.year}, ${u.month}, ${u.day}, ${u.hour}, ${u.minute}, ${u.second})';
}

String _firstNonEmpty(List<String?> candidates) =>
    candidates.firstWhere((c) => c != null && c.trim().isNotEmpty, orElse: () => '')!.trim();
