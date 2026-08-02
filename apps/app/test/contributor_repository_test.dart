import 'dart:convert';

import 'package:app/feature/contributor/data/contributor_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Map<String, dynamic> entry(
    String login, {
    String type = 'User',
    int contributions = 1,
  }) => {
    'login': login,
    'avatar_url': 'https://avatars.githubusercontent.com/$login',
    'html_url': 'https://github.com/$login',
    'contributions': contributions,
    'type': type,
  };

  test('fetches every page and excludes non-user accounts', () async {
    final firstPage = [
      entry('alice', contributions: 115),
      entry('renovate[bot]', type: 'Bot'),
      for (var i = 0; i < 98; i++) entry('user$i'),
    ];
    final secondPage = [entry('zoe', contributions: 2)];
    final requestedPages = <String>[];

    final repository = ContributorRepository(
      client: MockClient((request) async {
        expect(request.url.host, 'api.github.com');
        expect(request.url.path, '/repos/FlutterKaigi/2026/contributors');
        expect(request.url.queryParameters['per_page'], '100');
        final page = request.url.queryParameters['page'];
        requestedPages.add(page ?? '');
        return http.Response(
          jsonEncode(page == '1' ? firstPage : secondPage),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final contributors = await repository.fetchContributors();

    expect(requestedPages, ['1', '2']);
    expect(contributors, hasLength(100));
    expect(contributors.first.login, 'alice');
    expect(contributors.first.contributions, 115);
    expect(contributors.first.htmlUrl, 'https://github.com/alice');
    expect(contributors.last.login, 'zoe');
    expect(
      contributors.where((contributor) => contributor.login.contains('[bot]')),
      isEmpty,
    );
  });

  test('throws when the GitHub API returns an error status', () async {
    final repository = ContributorRepository(
      client: MockClient((request) async => http.Response('', 403)),
    );

    await expectLater(
      repository.fetchContributors(),
      throwsA(isA<http.ClientException>()),
    );
  });
}
