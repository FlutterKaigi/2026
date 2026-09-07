import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExchangeToken', () {
    test('isExpired is false before expiresAt and true after it', () {
      final future = ExchangeToken(
        value: 'v1.uid-1.9999999999.abcdef',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      final past = ExchangeToken(
        value: 'v1.uid-1.1.abcdef',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(future.isExpired, isFalse);
      expect(past.isExpired, isTrue);
    });

    test('qrPayload embeds the token value under the share base URL', () {
      final token = ExchangeToken(value: 'v1.uid-1.9999999999.abcdef', expiresAt: DateTime.utc(2026, 8));
      expect(token.qrPayload, '$exchangeShareBaseUrl/v1.uid-1.9999999999.abcdef');
    });
  });

  group('parseScannedExchangeToken', () {
    test('accepts a bare token and extracts its uid', () {
      final scanned = parseScannedExchangeToken('v1.other-uid.9999999999.deadbeef');
      expect(scanned, (token: 'v1.other-uid.9999999999.deadbeef', otherUid: 'other-uid'));
    });

    test('accepts the share URL form and extracts the token and uid', () {
      final scanned = parseScannedExchangeToken('$exchangeShareBaseUrl/v1.other-uid.9999999999.deadbeef');
      expect(scanned, (token: 'v1.other-uid.9999999999.deadbeef', otherUid: 'other-uid'));
    });

    test('trims surrounding whitespace', () {
      final scanned = parseScannedExchangeToken('  v1.other-uid.9999999999.deadbeef  ');
      expect(scanned?.otherUid, 'other-uid');
    });

    test('rejects an unrelated URL', () {
      expect(parseScannedExchangeToken('https://example.com/v1.other-uid.9999999999.deadbeef'), isNull);
    });

    test('rejects a token with an unknown version', () {
      expect(parseScannedExchangeToken('v2.other-uid.9999999999.deadbeef'), isNull);
    });

    test('rejects a token with a non-numeric expiry', () {
      expect(parseScannedExchangeToken('v1.other-uid.not-a-number.deadbeef'), isNull);
    });

    test('rejects a token with an uppercase signature', () {
      expect(parseScannedExchangeToken('v1.other-uid.9999999999.DEADBEEF'), isNull);
    });

    test('rejects arbitrary text', () {
      expect(parseScannedExchangeToken('not a token'), isNull);
    });
  });
}
