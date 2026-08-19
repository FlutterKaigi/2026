/// Generates `apps/website/lib/constants/generated_staff.dart` from the
/// `staffMembers` Firestore collection managed by `packages/data` (the same
/// data the admin dashboard writes), or a local sample fixture as a fallback.
///
/// The output is **git-ignored** and regenerated on every build, so staff
/// personal data is never committed to the git history (see `.gitignore`).
/// Avatar images are NOT processed here: `iconUrl` is passed through as-is and
/// the site renders a placeholder when it is empty.
///
/// Run via:
///
/// ```sh
/// # Local: reads the Firestore emulator (start it + seed first, e.g.
/// #   fvm dart run melos firebase:start  /  fvm dart run melos firebase:seed)
/// fvm dart run melos staff:generate
///
/// # STG / prod: point at the real project over HTTPS.
/// FIREBASE_PROJECT_ID=flutterkaigi-2026-stg \
///   FIRESTORE_HOST=firestore.googleapis.com \
///   FIRESTORE_ACCESS_TOKEN=$(gcloud auth print-access-token) \
///   fvm dart run tool/generate_staff.dart
/// ```
///
/// Data source (Firestore REST API, mirroring `tool/generate_sponsors.dart`):
///   - `FIREBASE_PROJECT_ID`     — defaults to `dev-flutterkaigi-2026`.
///   - `FIRESTORE_EMULATOR_HOST` — when set (or the host is localhost), talk to
///     the emulator over HTTP with the `owner` bearer token.
///   - `FIRESTORE_HOST`          — explicit host for a real project (HTTPS).
///   - `FIRESTORE_ACCESS_TOKEN`  — OAuth bearer token for a real project.
///   - `FIRESTORE_API_KEY`       — optional `?key=` for a real project.
///   - If Firestore is unreachable, fall back to `tool/staff/sample_staff.json`
///     so offline/preview builds still render placeholders. A *reachable but
///     empty* collection yields an empty section (no fake data).
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _outFile = 'apps/website/lib/constants/generated_staff.dart';
const _sampleFile = 'tool/staff/sample_staff.json';

// Firestore defaults — kept in sync with tool/generate_sponsors.dart.
const _defaultProjectId = 'dev-flutterkaigi-2026';
const _defaultFirestoreHost = 'localhost:8080';

Future<void> main(List<String> args) async {
  final entries = await _loadStaff();
  if (entries.isEmpty) {
    stderr.writeln('warning: no staff members found in the data source.');
  }

  _writeDart(entries);
  _format(_outFile);

  stdout.writeln('Wrote $_outFile (${entries.length} staff member(s)).');
}

// ── Data loading ──────────────────────────────────────────────────────────

Future<List<_Staff>> _loadStaff() async {
  try {
    final staff = await _fetchFirestoreStaff();
    stdout.writeln('Loaded ${staff.length} staff member(s) from Firestore.');
    // A reachable but empty collection is a valid state (e.g. data not seeded
    // yet) — emit an empty section rather than masking it with fake data.
    return _sorted(staff);
  } catch (e) {
    stderr.writeln(
      'warning: could not load staff from Firestore ($e).\n'
      'Falling back to $_sampleFile — placeholder staff will be shown.',
    );
    return _sorted(_loadSampleStaff());
  }
}

/// Display order: the dashboard-managed `order` ascending, then document id as
/// a stable tie-breaker.
List<_Staff> _sorted(List<_Staff> staff) {
  return staff..sort((s1, s2) {
    final byOrder = s1.order.compareTo(s2.order);
    return byOrder != 0 ? byOrder : s1.id.compareTo(s2.id);
  });
}

/// Fetches every document in the `staffMembers` collection via the Firestore
/// REST API and maps each to the website [_Staff] model.
///
/// Talks to the local emulator by default; set the `FIRESTORE_*` /
/// `FIREBASE_PROJECT_ID` env vars (see the library doc) to target STG/prod.
Future<List<_Staff>> _fetchFirestoreStaff() async {
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
    'Fetching staff from Firestore '
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
      '/databases/(default)/documents/staffMembers';

  final staff = <_Staff>[];
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
      staff.add(_Staff.fromModel(_decodeFirestoreDoc(doc)));
    }
    pageToken = decoded['nextPageToken'] as String?;
  } while (pageToken != null && pageToken.isNotEmpty);

  return staff;
}

List<_Staff> _loadSampleStaff() {
  final decoded = jsonDecode(File(_sampleFile).readAsStringSync());
  return _extractList(decoded).map(_Staff.fromModel).toList();
}

/// Accepts a bare array or a `{staff|staffMembers|data|items: [...]}` envelope.
List<Map<String, dynamic>> _extractList(Object? decoded) {
  final list = switch (decoded) {
    final List<dynamic> l => l,
    {'staff': final List<dynamic> l} => l,
    {'staffMembers': final List<dynamic> l} => l,
    {'data': final List<dynamic> l} => l,
    {'items': final List<dynamic> l} => l,
    _ => const <dynamic>[],
  };
  return list.whereType<Map<String, dynamic>>().toList();
}

String _normalizeHost(String host) {
  var value = host.trim().replaceFirst(RegExp(r'^https?://'), '');
  while (value.endsWith('/')) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}

// ── Firestore REST decoding (mirrors tool/generate_sponsors.dart) ──────────

/// Decodes a Firestore REST document (`{name, fields, ...}`) into a plain map
/// of the `packages/data` `StaffMember` model, injecting the doc id.
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

void _writeDart(List<_Staff> staff) {
  final out = StringBuffer()
    ..writeln('// GENERATED FILE — do not edit by hand and do not commit.')
    ..writeln('// Source of truth: the `staffMembers` Firestore collection (packages/data),')
    ..writeln('// or tool/staff/sample_staff.json when Firestore is unreachable.')
    ..writeln('// Regenerate via: fvm dart run melos staff:generate')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars, directives_ordering')
    ..writeln()
    ..writeln("import 'staff.dart';")
    ..writeln()
    ..writeln('const List<StaffEntry> generatedStaff = [');

  for (final s in staff) {
    out
      ..writeln('  StaffEntry(')
      ..writeln('    name: ${_str(s.name)},')
      ..writeln('    iconUrl: ${_str(s.iconUrl)},');
    if (s.greeting.isNotEmpty) {
      out.writeln('    greeting: ${_str(s.greeting)},');
    }
    if (s.snsLinks.isNotEmpty) {
      out.writeln('    snsLinks: [');
      for (final l in s.snsLinks) {
        out.writeln('      StaffSnsLink(type: ${_str(l.type)}, value: ${_str(l.value)}),');
      }
      out.writeln('    ],');
    }
    out.writeln('  ),');
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

// ── Internal model ──────────────────────────────────────────────────────────

class _Staff {
  _Staff({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.greeting,
    required this.snsLinks,
    required this.order,
  });

  /// Maps a decoded `packages/data` `StaffMember` document to the website
  /// model. Optional fields (`greeting`, `snsLinks`) normalize to empty and
  /// blank SNS entries are dropped so the site never renders dead links.
  factory _Staff.fromModel(Map<String, dynamic> m) {
    final snsLinks = <_SnsLink>[];
    for (final raw in (m['snsLinks'] as List?) ?? const []) {
      if (raw is! Map) continue;
      final type = (raw['type'] ?? '').toString().trim();
      final value = (raw['value'] ?? '').toString().trim();
      if (type.isNotEmpty && value.isNotEmpty) {
        snsLinks.add(_SnsLink(type: type, value: value));
      }
    }
    return _Staff(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? '').toString().trim(),
      iconUrl: (m['iconUrl'] ?? '').toString().trim(),
      greeting: (m['greeting'] ?? '').toString().trim(),
      snsLinks: snsLinks,
      order: switch (m['order']) {
        final int o => o,
        final String o => int.tryParse(o) ?? 0,
        _ => 0,
      },
    );
  }

  final String id;
  final String name;
  final String iconUrl;
  final String greeting;
  final List<_SnsLink> snsLinks;
  final int order;
}

class _SnsLink {
  _SnsLink({required this.type, required this.value});
  final String type;
  final String value;
}
