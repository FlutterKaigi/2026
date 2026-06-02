import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

final class FirebaseDataClient {
  FirebaseDataClient({
    required this.projectId,
    required String host,
    http.Client? httpClient,
  }) : host = _normalizeHost(host),
       _httpClient = httpClient ?? http.Client();

  factory FirebaseDataClient.emulator({
    String projectId = 'dev-flutterkaigi-2026',
    String host = 'localhost:8080',
    http.Client? httpClient,
  }) {
    return FirebaseDataClient(
      projectId: projectId,
      host: host,
      httpClient: httpClient,
    );
  }

  final String projectId;
  final String host;
  final http.Client _httpClient;

  Future<List<FirestoreDocument>> listDocuments({
    required String collectionPath,
    String? orderBy,
  }) async {
    final uri = _buildDocumentsUri(
      collectionPath: collectionPath,
      orderBy: orderBy,
    );
    final response = await _httpClient.get(uri);
    if (response.statusCode == 404) {
      return const [];
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FirebaseDataException(
        'Firestore request failed with HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw const FirebaseDataException('Firestore response must be a JSON object.');
    }

    final documents = decoded['documents'];
    if (documents == null) {
      return const [];
    }
    if (documents is! List) {
      throw const FirebaseDataException('Firestore response field "documents" must be an array.');
    }

    return [
      for (final document in documents) FirestoreDocument.fromJson(document),
    ];
  }

  Uri _buildDocumentsUri({
    required String collectionPath,
    String? orderBy,
  }) {
    final hostUri = Uri.parse('http://$host');
    final query = orderBy == null ? null : 'orderBy=${Uri.encodeComponent(orderBy)}';
    return Uri(
      scheme: hostUri.scheme,
      host: hostUri.host,
      port: hostUri.hasPort ? hostUri.port : null,
      pathSegments: [
        'v1',
        'projects',
        projectId,
        'databases',
        '(default)',
        'documents',
        ...collectionPath.split('/').where((segment) => segment.isNotEmpty),
      ],
      query: query,
    );
  }
}

final class FirestoreDocument {
  const FirestoreDocument({
    required this.name,
    required this.fields,
  });

  factory FirestoreDocument.fromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FirebaseDataException('Firestore document must be a JSON object.');
    }

    final name = value['name'];
    final rawFields = value['fields'];
    if (name is! String) {
      throw const FirebaseDataException('Firestore document field "name" must be a string.');
    }
    if (rawFields is! Map<String, Object?>) {
      throw const FirebaseDataException('Firestore document field "fields" must be an object.');
    }

    return FirestoreDocument(
      name: name,
      fields: {
        for (final entry in rawFields.entries) entry.key: _decodeFirestoreValue(entry.value),
      },
    );
  }

  final String name;
  final Map<String, Object?> fields;

  String get id => name.split('/').last;
}

Object? _decodeFirestoreValue(Object? value) {
  if (value is! Map<String, Object?>) {
    throw const FirebaseDataException('Firestore value must be a JSON object.');
  }

  if (value.containsKey('nullValue')) return null;
  if (value['booleanValue'] case final bool v) return v;
  if (value['integerValue'] case final String v) return int.parse(v);
  if (value['integerValue'] case final int v) return v;
  if (value['doubleValue'] case final num v) return v.toDouble();
  if (value['stringValue'] case final String v) return v;
  if (value['timestampValue'] case final String v) return DateTime.parse(v);
  if (value['arrayValue'] case final Map<String, Object?> v) {
    final values = v['values'];
    if (values == null) return const <Object?>[];
    if (values is! List) {
      throw const FirebaseDataException('Firestore arrayValue.values must be an array.');
    }
    return [for (final item in values) _decodeFirestoreValue(item)];
  }
  if (value['mapValue'] case final Map<String, Object?> v) {
    final fields = v['fields'];
    if (fields == null) return const <String, Object?>{};
    if (fields is! Map<String, Object?>) {
      throw const FirebaseDataException('Firestore mapValue.fields must be an object.');
    }
    return {
      for (final entry in fields.entries) entry.key: _decodeFirestoreValue(entry.value),
    };
  }

  throw FirebaseDataException('Unsupported Firestore value: ${jsonEncode(value)}');
}

String _normalizeHost(String host) {
  var value = host.trim();
  value = value.replaceFirst(RegExp(r'^https?://'), '');
  while (value.endsWith('/')) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}

final class FirebaseDataException implements Exception {
  const FirebaseDataException(this.message);

  final String message;

  @override
  String toString() => 'FirebaseDataException: $message';
}
