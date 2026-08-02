import 'dart:async';
import 'dart:convert';

import 'package:app/feature/contributor/data/model/contributor.dart';
import 'package:http/http.dart' as http;

/// Fetches contributors of the FlutterKaigi 2026 repository from the GitHub
/// REST API.
class ContributorRepository {
  const ContributorRepository({http.Client? client}) : _client = client;

  final http.Client? _client;

  static const _host = 'api.github.com';
  static const _path = '/repos/FlutterKaigi/2026/contributors';
  static const _pageSize = 100;

  // The GitHub API caps `per_page` at 100; the page limit is a safety stop so
  // an unexpectedly long listing cannot loop forever.
  static const _maxPages = 10;

  Future<List<Contributor>> fetchContributors() async {
    final client = _client ?? http.Client();
    try {
      final contributors = <Contributor>[];
      for (var page = 1; page <= _maxPages; page++) {
        final entries = await _fetchPage(client, page: page);
        contributors.addAll(
          entries
              .whereType<Map<String, dynamic>>()
              .map(Contributor.fromJson)
              .where((contributor) => contributor.isUser),
        );
        if (entries.length < _pageSize) {
          break;
        }
      }
      return contributors;
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<List<dynamic>> _fetchPage(
    http.Client client, {
    required int page,
  }) async {
    final uri = Uri.https(_host, _path, {
      'per_page': '$_pageSize',
      'page': '$page',
    });
    final response = await client
        .get(uri, headers: const {'Accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw http.ClientException(
        'GitHub API returned status ${response.statusCode}',
        uri,
      );
    }
    return json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
  }
}
