import 'package:data/src/repository/sponsor_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePublishedSponsor', () {
    test('parses a complete sponsor with a primary logo', () {
      final sponsor = parsePublishedSponsor(
        id: 'sponsor-001',
        data: _sponsorData(),
      );

      expect(sponsor?.id, 'sponsor-001');
      expect(sponsor?.name.ja, 'スポンサー');
    });

    test('skips a draft without a primary logo before strict parsing', () {
      final sponsor = parsePublishedSponsor(
        id: 'draft-001',
        data: <String, dynamic>{
          'name': {'ja': '入力中'},
          'primaryLogoUrl': '',
        },
      );

      expect(sponsor, isNull);
    });

    test('skips a malformed document instead of failing the sponsor wall', () {
      final reportedErrors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = reportedErrors.add;
      addTearDown(() => FlutterError.onError = originalOnError);

      final sponsor = parsePublishedSponsor(
        id: 'malformed-001',
        data: <String, dynamic>{
          ..._sponsorData(),
          'description': {'ja': '日本語だけ'},
        },
      );

      expect(sponsor, isNull);
      expect(reportedErrors, hasLength(1));
      expect(
        reportedErrors.single.context.toString(),
        contains('malformed-001'),
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
