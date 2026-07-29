import 'package:data/src/repository/sponsor_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSponsorDocument', () {
    test('parses a complete sponsor when a primary logo is required', () {
      final sponsor = parseSponsorDocument(
        id: 'published-001',
        data: _sponsorData(),
        requirePrimaryLogo: true,
      );

      expect(sponsor?.id, 'published-001');
    });

    test('skips an incomplete draft before strict conversion', () {
      final sponsor = parseSponsorDocument(
        id: 'draft-001',
        data: <String, dynamic>{
          'name': {'ja': '入力中'},
          'primaryLogoUrl': '',
        },
        requirePrimaryLogo: true,
      );

      expect(sponsor, isNull);
    });

    test('does not hide a malformed published sponsor', () {
      expect(
        () => parseSponsorDocument(
          id: 'malformed-001',
          data: <String, dynamic>{
            'primaryLogoUrl': 'https://example.com/logo.png',
          },
          requirePrimaryLogo: true,
        ),
        throwsA(isA<TypeError>()),
      );
    });

    test('keeps a sponsor without a logo when publication is not required', () {
      final sponsor = parseSponsorDocument(
        id: 'dashboard-001',
        data: <String, dynamic>{
          ..._sponsorData(),
          'primaryLogoUrl': null,
        },
        requirePrimaryLogo: false,
      );

      expect(sponsor?.id, 'dashboard-001');
      expect(sponsor?.primaryLogoUrl, isNull);
    });
  });
}

Map<String, dynamic> _sponsorData() => <String, dynamic>{
  'name': {'ja': 'スポンサー', 'en': 'Sponsor'},
  'description': {'ja': '説明', 'en': 'Description'},
  'primaryLogoUrl': 'https://example.com/logo.png',
  'secondaryLogoUrl': null,
  'tier': 'gold',
  'slug': 'sponsor',
  'xUrl': null,
  'websiteUrl': 'https://example.com',
  'recruitUrl': null,
  'jobBoardUrl': null,
  'createdAt': DateTime.utc(2026),
  'updatedAt': DateTime.utc(2026),
};
