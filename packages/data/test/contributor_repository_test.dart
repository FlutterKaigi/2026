import 'package:data/src/repository/contributor_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseContributorDocument', () {
    test('parses a complete document', () {
      final contributor = parseContributorDocument(
        id: 'alice',
        data: <String, dynamic>{
          'login': 'alice',
          'avatarUrl': 'https://avatars.githubusercontent.com/alice',
          'htmlUrl': 'https://github.com/alice',
          'contributions': 115,
        },
      );

      expect(contributor.login, 'alice');
      expect(contributor.avatarUrl, 'https://avatars.githubusercontent.com/alice');
      expect(contributor.htmlUrl, 'https://github.com/alice');
      expect(contributor.contributions, 115);
    });

    test('takes the login from the document ID over the field', () {
      final contributor = parseContributorDocument(
        id: 'renamed-login',
        data: <String, dynamic>{
          'login': 'stale-login',
          'avatarUrl': 'https://avatars.githubusercontent.com/renamed-login',
          'htmlUrl': 'https://github.com/renamed-login',
          'contributions': 3,
        },
      );

      expect(contributor.login, 'renamed-login');
    });

    test('ignores unknown fields such as updatedAt', () {
      final contributor = parseContributorDocument(
        id: 'alice',
        data: <String, dynamic>{
          'login': 'alice',
          'avatarUrl': 'https://avatars.githubusercontent.com/alice',
          'htmlUrl': 'https://github.com/alice',
          'contributions': 1,
          'updatedAt': '2026-08-03T00:00:00Z',
        },
      );

      expect(contributor.contributions, 1);
    });
  });
}
