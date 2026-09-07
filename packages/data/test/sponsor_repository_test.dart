import 'package:data/src/repository/sponsor_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSponsorDocument', () {
    test('parses a complete sponsor without a primary logo', () {
      final sponsor = parseSponsorDocument(
        id: 'logo-less-001',
        data: <String, dynamic>{
          ..._sponsorData(),
          'primaryLogoUrl': null,
        },
        excludeUnsupportedTiers: true,
      );

      expect(sponsor?.id, 'logo-less-001');
      expect(sponsor?.primaryLogoUrl, isNull);
    });

    test('skips an unsupported tier when requested', () {
      final sponsor = parseSponsorDocument(
        id: 'unsupported-001',
        data: <String, dynamic>{
          ..._sponsorData(),
          'tier': 'GENDAスペシャル',
        },
        excludeUnsupportedTiers: true,
      );

      expect(sponsor, isNull);
    });

    test('keeps strict tier conversion for other consumers', () {
      expect(
        () => parseSponsorDocument(
          id: 'unsupported-001',
          data: <String, dynamic>{
            ..._sponsorData(),
            'tier': 'GENDAスペシャル',
          },
          excludeUnsupportedTiers: false,
        ),
        throwsArgumentError,
      );
    });

    test('parses a complete sponsor in strict mode', () {
      final sponsor = parseSponsorDocument(
        id: 'dashboard-001',
        data: _sponsorData(),
        excludeUnsupportedTiers: false,
      );

      expect(sponsor?.id, 'dashboard-001');
      expect(sponsor?.primaryLogoUrl, isNotNull);
    });

    test('keeps a missing tier as a conversion error', () {
      expect(
        () => parseSponsorDocument(
          id: 'missing-tier-001',
          data: <String, dynamic>{..._sponsorData()}..remove('tier'),
          excludeUnsupportedTiers: true,
        ),
        throwsArgumentError,
      );
    });

    test('keeps a non-string tier as a conversion error', () {
      expect(
        () => parseSponsorDocument(
          id: 'invalid-tier-001',
          data: <String, dynamic>{
            ..._sponsorData(),
            'tier': 1,
          },
          excludeUnsupportedTiers: true,
        ),
        throwsArgumentError,
      );
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
