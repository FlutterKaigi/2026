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
