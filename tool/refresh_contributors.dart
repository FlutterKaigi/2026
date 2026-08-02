/// Refreshes the Firestore `contributors` collection from the GitHub API.
///
/// Fetches the contributor list of the repository (default `FlutterKaigi/2026`),
/// excludes bot accounts, and mirrors the result into Firestore: every current
/// contributor is upserted (document ID = GitHub login) and documents for
/// accounts that no longer appear are deleted. Runs daily on GitHub Actions via
/// `.github/workflows/refresh_contributors.yaml`.
///
/// Run via:
///
/// ```sh
/// # Local: writes to the Firestore emulator (start + use it first, e.g.
/// #   fvm dart run melos firebase:start)
/// fvm dart run melos contributors:refresh
///
/// # STG / prod: point at the real project over HTTPS.
/// FIREBASE_PROJECT_ID=flutterkaigi-2026-stg \
///   FIRESTORE_HOST=firestore.googleapis.com \
///   FIRESTORE_ACCESS_TOKEN=$(gcloud auth print-access-token) \
///   fvm dart run tool/refresh_contributors.dart
/// ```
///
/// Environment variables (mirroring `tool/generate_sponsors.dart`):
///   - `GITHUB_REPOSITORY`       — `owner/repo` to fetch. Defaults to `FlutterKaigi/2026`
///     (set automatically on GitHub Actions).
///   - `GITHUB_TOKEN`            — optional GitHub API token. Raises the rate limit and is
///     set automatically on GitHub Actions; anonymous access works locally.
///   - `FIREBASE_PROJECT_ID`     — defaults to `dev-flutterkaigi-2026`.
///   - `FIRESTORE_EMULATOR_HOST` — emulator host (HTTP, `owner` bearer). Defaults to
///     `localhost:8080` when `FIRESTORE_HOST` is not set.
///   - `FIRESTORE_HOST`          — explicit host for a real project (HTTPS).
///   - `FIRESTORE_ACCESS_TOKEN`  — OAuth bearer token for a real project. Required with
///     `FIRESTORE_HOST`.
library;

import 'dart:convert';
import 'dart:io';

const _defaultRepository = 'FlutterKaigi/2026';
const _defaultProjectId = 'dev-flutterkaigi-2026';
const _defaultEmulatorHost = 'localhost:8080';
const _collectionId = 'contributors';

// The GitHub API caps `per_page` at 100; the page limit is a safety stop so an
// unexpectedly long listing cannot loop forever.
const _gitHubPageSize = 100;
const _gitHubMaxPages = 10;
const _firestorePageSize = 300;

Future<void> main() async {
  final repository = Platform.environment['GITHUB_REPOSITORY'] ?? _defaultRepository;
  final firestore = _FirestoreTarget.fromEnvironment();

  final client = HttpClient();
  try {
    final contributors = await _fetchContributors(client, repository: repository);
    stdout.writeln('Fetched ${contributors.length} contributor(s) from $repository.');
    if (contributors.isEmpty) {
      // A repository always has at least one contributor; an empty list means
      // the API misbehaved. Keep the existing documents instead of wiping them.
      throw const FormatException('GitHub returned no contributors; aborting without changes.');
    }

    final existingIds = await _listDocumentIds(client, firestore);
    final updatedAt = DateTime.now().toUtc().toIso8601String();
    for (final contributor in contributors) {
      await _upsertContributor(client, firestore, contributor: contributor, updatedAt: updatedAt);
    }

    final staleIds = existingIds.difference({for (final contributor in contributors) contributor.login});
    for (final id in staleIds) {
      await _deleteDocument(client, firestore, id: id);
    }

    stdout.writeln(
      'Upserted ${contributors.length} and deleted ${staleIds.length} document(s) '
      'in ${firestore.projectId}/$_collectionId.',
    );
  } finally {
    client.close(force: true);
  }
}

class _Contributor {
  const _Contributor({
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.contributions,
  });

  final String login;
  final String avatarUrl;
  final String htmlUrl;
  final int contributions;
}

/// Connection details for the Firestore REST API (emulator or real project).
class _FirestoreTarget {
  const _FirestoreTarget({
    required this.host,
    required this.projectId,
    required this.isEmulator,
    required this.accessToken,
  });

  factory _FirestoreTarget.fromEnvironment() {
    final environment = Platform.environment;
    final projectId = environment['FIREBASE_PROJECT_ID'] ?? _defaultProjectId;
    final realHost = environment['FIRESTORE_HOST'];

    if (realHost != null && realHost.isNotEmpty) {
      final accessToken = environment['FIRESTORE_ACCESS_TOKEN'];
      if (accessToken == null || accessToken.isEmpty) {
        throw const FormatException('FIRESTORE_ACCESS_TOKEN is required when FIRESTORE_HOST is set.');
      }
      return _FirestoreTarget(
        host: realHost,
        projectId: projectId,
        isEmulator: false,
        accessToken: accessToken,
      );
    }

    return _FirestoreTarget(
      host: environment['FIRESTORE_EMULATOR_HOST'] ?? _defaultEmulatorHost,
      projectId: projectId,
      isEmulator: true,
      accessToken: 'owner',
    );
  }

  final String host;
  final String projectId;
  final bool isEmulator;
  final String accessToken;

  Uri uri(String pathSuffix, [Map<String, String>? queryParameters]) {
    final path =
        '/v1/projects/${Uri.encodeComponent(projectId)}/databases/(default)/documents'
        '$pathSuffix';
    return isEmulator ? Uri.http(host, path, queryParameters) : Uri.https(host, path, queryParameters);
  }
}

Future<List<_Contributor>> _fetchContributors(HttpClient client, {required String repository}) async {
  final token = Platform.environment['GITHUB_TOKEN'];
  final contributors = <_Contributor>[];

  for (var page = 1; page <= _gitHubMaxPages; page++) {
    final uri = Uri.https('api.github.com', '/repos/$repository/contributors', {
      'per_page': '$_gitHubPageSize',
      'page': '$page',
    });
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    request.headers.set(HttpHeaders.userAgentHeader, 'flutterkaigi-2026-refresh-contributors');
    if (token != null && token.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }

    final response = await request.close();
    final body = await utf8.decodeStream(response);
    if (response.statusCode != 200) {
      throw HttpException('GitHub API returned HTTP ${response.statusCode}: $body', uri: uri);
    }

    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw FormatException('GitHub API must return a JSON array, got: $body');
    }

    for (final entry in decoded) {
      if (entry is! Map) continue;
      final login = entry['login'];
      // Bots (e.g. renovate[bot]) have type `Bot` and are not credited.
      if (entry['type'] != 'User' || login is! String || login.isEmpty) {
        continue;
      }
      contributors.add(
        _Contributor(
          login: login,
          avatarUrl: entry['avatar_url'] as String? ?? '',
          htmlUrl: entry['html_url'] as String? ?? 'https://github.com/$login',
          contributions: (entry['contributions'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    if (decoded.length < _gitHubPageSize) {
      break;
    }
  }

  return contributors;
}

Future<Set<String>> _listDocumentIds(HttpClient client, _FirestoreTarget firestore) async {
  final ids = <String>{};
  String? pageToken;

  do {
    final uri = firestore.uri('/$_collectionId', {
      'pageSize': '$_firestorePageSize',
      if (pageToken != null) 'pageToken': pageToken,
    });
    final body = await _sendFirestoreRequest(client, firestore, method: 'GET', uri: uri);
    final decoded = jsonDecode(body.isEmpty ? '{}' : body);
    if (decoded is! Map) {
      throw FormatException('Firestore list response must be a JSON object, got: $body');
    }

    final documents = decoded['documents'];
    if (documents is List) {
      for (final document in documents) {
        if (document is! Map) continue;
        final name = document['name'];
        if (name is String && name.isNotEmpty) {
          ids.add(Uri.decodeComponent(name.split('/').last));
        }
      }
    }
    pageToken = decoded['nextPageToken'] as String?;
  } while (pageToken != null);

  return ids;
}

Future<void> _upsertContributor(
  HttpClient client,
  _FirestoreTarget firestore, {
  required _Contributor contributor,
  required String updatedAt,
}) async {
  final uri = firestore.uri('/$_collectionId/${Uri.encodeComponent(contributor.login)}');
  final payload = jsonEncode({
    'fields': {
      'login': {'stringValue': contributor.login},
      'avatarUrl': {'stringValue': contributor.avatarUrl},
      'htmlUrl': {'stringValue': contributor.htmlUrl},
      'contributions': {'integerValue': '${contributor.contributions}'},
      'updatedAt': {'timestampValue': updatedAt},
    },
  });
  await _sendFirestoreRequest(client, firestore, method: 'PATCH', uri: uri, body: payload);
}

Future<void> _deleteDocument(HttpClient client, _FirestoreTarget firestore, {required String id}) async {
  final uri = firestore.uri('/$_collectionId/${Uri.encodeComponent(id)}');
  await _sendFirestoreRequest(client, firestore, method: 'DELETE', uri: uri);
  stdout.writeln('Deleted stale contributor document: $id');
}

Future<String> _sendFirestoreRequest(
  HttpClient client,
  _FirestoreTarget firestore, {
  required String method,
  required Uri uri,
  String? body,
}) async {
  final request = await client.openUrl(method, uri);
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${firestore.accessToken}');
  if (body != null) {
    request.headers.contentType = ContentType.json;
    request.write(body);
  }

  final response = await request.close();
  final responseBody = await utf8.decodeStream(response);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'Firestore $method ${uri.path} failed: HTTP ${response.statusCode}\n$responseBody',
      uri: uri,
    );
  }
  return responseBody;
}
