import 'package:data/data.dart';
import 'package:data/src/repository/profile_exchange_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseProfileExchangeDocument', () {
    test('parses a document with a resolved createdAt', () {
      final exchange = parseProfileExchangeDocument(
        id: 'other-uid-1',
        data: <String, dynamic>{
          'createdAt': DateTime.utc(2026, 8, 2),
          'origin': 'scan',
          'token': null,
          'note': null,
        },
        hasPendingWrites: false,
      );

      expect(exchange.id, 'other-uid-1');
      expect(exchange.createdAt, DateTime.utc(2026, 8, 2));
      expect(exchange.origin, ProfileExchangeOrigin.scan);
    });

    test('fills a still-pending createdAt with the current time', () {
      final before = DateTime.now();
      final exchange = parseProfileExchangeDocument(
        id: 'other-uid-1',
        data: <String, dynamic>{
          'createdAt': null,
          'origin': 'scan',
          'token': 'v1.other-uid-1.9999999999.signature',
        },
        hasPendingWrites: true,
      );
      final after = DateTime.now();

      expect(exchange.createdAt.isBefore(before), isFalse);
      expect(exchange.createdAt.isAfter(after), isFalse);
    });

    test('keeps a resolved createdAt untouched even with pending writes', () {
      final exchange = parseProfileExchangeDocument(
        id: 'other-uid-1',
        data: <String, dynamic>{
          'createdAt': DateTime.utc(2026, 8, 2),
          'origin': 'mirror',
        },
        hasPendingWrites: true,
      );

      expect(exchange.createdAt, DateTime.utc(2026, 8, 2));
    });
  });
}
