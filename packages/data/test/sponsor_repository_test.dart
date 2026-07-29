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
        skipMalformedDocument: true,
      );

      expect(sponsor?.id, 'logo-less-001');
      expect(sponsor?.primaryLogoUrl, isNull);
    });

    test('skips an incomplete draft when requested', () {
      final sponsor = parseSponsorDocument(
        id: 'draft-001',
        data: <String, dynamic>{
          'name': {'ja': '入力中'},
        },
        skipMalformedDocument: true,
      );

      expect(sponsor, isNull);
    });

    test('keeps strict conversion for other consumers', () {
      expect(
        () => parseSponsorDocument(
          id: 'malformed-001',
          data: <String, dynamic>{},
          skipMalformedDocument: false,
        ),
        throwsA(isA<TypeError>()),
      );
    });

    test('parses a complete sponsor in strict mode', () {
      final sponsor = parseSponsorDocument(
        id: 'dashboard-001',
        data: _sponsorData(),
        skipMalformedDocument: false,
      );

      expect(sponsor?.id, 'dashboard-001');
      expect(sponsor?.primaryLogoUrl, isNotNull);
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
