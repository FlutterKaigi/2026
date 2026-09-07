/// Minimal Firestore REST API client — Flutter-free (only `dart:convert`,
/// `dart:io`, and `package:http`), so it can be imported from plain `dart
/// run` scripts (e.g. `tool/generate_news.dart`) that cannot compile
/// `cloud_firestore` (a Flutter plugin) or any other Flutter-framework code.
///
/// Mirrors the encoding used by `tool/firebase_seed.dart` on the write side.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Connection details for a Firestore REST API endpoint.
class FirestoreRestConfig {
  const FirestoreRestConfig({
    required this.projectId,
    required this.host,
    this.isEmulator = false,
    this.accessToken,
    this.apiKey,
  });

  final String projectId;
  final String host;

  /// Whether [host] is the local Firestore emulator (plain HTTP, `owner`
  /// bearer token) rather than a real STG/prod project (HTTPS).
  final bool isEmulator;

  /// OAuth bearer token for a real (non-emulator) project.
  final String? accessToken;

  /// Optional `?key=` for a real (non-emulator) project.
  final String? apiKey;
}

/// Fetches every document in [collection] via the Firestore REST API,
/// decoding each into a plain `Map<String, dynamic>` — Firestore's typed
/// field wrappers (`stringValue`, `mapValue`, etc.) unwrapped, with the
/// document id injected as `'id'`.
Future<List<Map<String, dynamic>>> fetchFirestoreDocuments(
  String collection,
  FirestoreRestConfig config, {
  http.Client? client,
}) async {
  final httpClient = client ?? http.Client();
  final scheme = config.isEmulator ? 'http' : 'https';
  final headers = <String, String>{
    'Accept': 'application/json',
    if (config.isEmulator)
      'Authorization': 'Bearer owner'
    else if (config.accessToken != null && config.accessToken!.isNotEmpty)
      'Authorization': 'Bearer ${config.accessToken}',
  };

  final base =
      '$scheme://${config.host}/v1/projects/${Uri.encodeComponent(config.projectId)}'
      '/databases/(default)/documents/$collection';

  final docs = <Map<String, dynamic>>[];
  String? pageToken;
  do {
    final query = <String>[
      'pageSize=300',
      if (pageToken != null && pageToken.isNotEmpty) 'pageToken=${Uri.encodeComponent(pageToken)}',
      if (config.apiKey != null && config.apiKey!.isNotEmpty) 'key=${Uri.encodeComponent(config.apiKey!)}',
    ];
    final uri = Uri.parse('$base?${query.join('&')}');
    final resp = await httpClient.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200) {
      throw HttpException('Firestore returned ${resp.statusCode}: ${resp.body}');
    }
    final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final rawDocs = (decoded['documents'] as List?) ?? const [];
    for (final doc in rawDocs.whereType<Map<String, dynamic>>()) {
      docs.add(_decodeFirestoreDoc(doc));
    }
    pageToken = decoded['nextPageToken'] as String?;
  } while (pageToken != null && pageToken.isNotEmpty);

  return docs;
}

/// Creates or updates the document at [path] (e.g. `sessions/1282478`) via the
/// Firestore REST API, encoding [data] into Firestore's typed field wrappers.
///
/// [updateMask] lists the field names the request is allowed to touch. It is
/// **strongly recommended**: a `PATCH` without a mask replaces the whole
/// document, deleting any field not present in [data]. Passing a mask makes
/// the write behave like `SetOptions(merge: true)` on the SDK side, which is
/// what lets `tool/import_sessions.dart` refresh Sessionize-owned fields
/// without clobbering values edited in the admin dashboard.
///
/// [DateTime] values are written as Firestore timestamps; nested maps and
/// lists are encoded recursively. Mirrors `_decodeFirestoreValue` below and
/// `_encodeFirestoreValue` in `tool/firebase_seed.dart`.
Future<void> upsertFirestoreDocument(
  String path,
  Map<String, Object?> data,
  FirestoreRestConfig config, {
  List<String>? updateMask,
  http.Client? client,
}) async {
  final httpClient = client ?? http.Client();
  final scheme = config.isEmulator ? 'http' : 'https';
  final headers = <String, String>{
    'Content-Type': 'application/json',
    if (config.isEmulator)
      'Authorization': 'Bearer owner'
    else if (config.accessToken != null && config.accessToken!.isNotEmpty)
      'Authorization': 'Bearer ${config.accessToken}',
  };

  final encodedPath = path.split('/').map(Uri.encodeComponent).join('/');
  final query = <String>[
    for (final field in updateMask ?? const <String>[]) 'updateMask.fieldPaths=${Uri.encodeComponent(field)}',
    if (config.apiKey != null && config.apiKey!.isNotEmpty) 'key=${Uri.encodeComponent(config.apiKey!)}',
  ];
  final uri = Uri.parse(
    '$scheme://${config.host}/v1/projects/${Uri.encodeComponent(config.projectId)}'
    '/databases/(default)/documents/$encodedPath${query.isEmpty ? '' : '?${query.join('&')}'}',
  );

  final resp = await httpClient
      .patch(
        uri,
        headers: headers,
        body: jsonEncode({'fields': encodeFirestoreFields(data)}),
      )
      .timeout(const Duration(seconds: 30));
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw HttpException('Firestore returned ${resp.statusCode} for $path: ${resp.body}');
  }
}

/// Encodes a plain field map into Firestore's typed field wrappers.
Map<String, Object?> encodeFirestoreFields(Map<String, Object?> data) {
  return {
    for (final entry in data.entries) entry.key: _encodeFirestoreValue(entry.value),
  };
}

Map<String, Object?> _encodeFirestoreValue(Object? value) {
  if (value == null) return {'nullValue': null};
  if (value is bool) return {'booleanValue': value};
  if (value is int) return {'integerValue': value.toString()};
  if (value is num) return {'doubleValue': value};
  if (value is DateTime) {
    return {'timestampValue': value.toUtc().toIso8601String()};
  }
  if (value is String) {
    // Seed JSON and `toJson()` output both carry timestamps as ISO-8601
    // strings; keep them typed as Firestore timestamps rather than strings.
    if (RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(value)) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return {'timestampValue': parsed.toUtc().toIso8601String()};
      }
    }
    return {'stringValue': value};
  }
  if (value is List) {
    final values = value.map(_encodeFirestoreValue).toList();
    return {
      'arrayValue': values.isEmpty ? <String, Object?>{} : {'values': values},
    };
  }
  if (value is Map) {
    final fields = encodeFirestoreFields(value.cast<String, Object?>());
    return {
      'mapValue': fields.isEmpty ? <String, Object?>{} : {'fields': fields},
    };
  }

  throw ArgumentError('Unsupported Firestore value: $value');
}

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
