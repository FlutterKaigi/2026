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

    test('qrPayload embeds the token value under the explicitly selected origin', () {
      final token = ExchangeToken(value: 'v1.uid-1.9999999999.abcdef', expiresAt: DateTime.utc(2026, 8));
      expect(token.qrPayload(origin: productionExchangeOrigin), '$productionExchangeOrigin/x/${token.value}');
      expect(token.qrPayload(origin: stagingExchangeOrigin), '$stagingExchangeOrigin/x/${token.value}');
      expect(token.qrPayload(origin: null), token.value);
    });
  });

  group('parseScannedExchangeToken', () {
    test('accepts a bare token and extracts its uid', () {
      final scanned = parseScannedExchangeToken('v1.other-uid.9999999999.deadbeef');
      expect(scanned, (token: 'v1.other-uid.9999999999.deadbeef', otherUid: 'other-uid'));
    });

    test('accepts the share URL form and extracts the token and uid', () {
      for (final origin in [productionExchangeOrigin, legacyExchangeOrigin]) {
        final scanned = parseScannedExchangeToken('$origin/x/v1.other-uid.9999999999.deadbeef');
        expect(scanned, (token: 'v1.other-uid.9999999999.deadbeef', otherUid: 'other-uid'));
      }
    });

    test('does not accept a staging link unless the caller allows its origin', () {
      const link = '$stagingExchangeOrigin/x/v1.other-uid.9999999999.deadbeef';
      expect(parseScannedExchangeToken(link), isNull);
      expect(
        parseScannedExchangeToken(link, allowedOrigins: {stagingExchangeOrigin}),
        (token: 'v1.other-uid.9999999999.deadbeef', otherUid: 'other-uid'),
      );
    });

    test('requires the exact HTTPS origin and a single token path segment', () {
      const token = 'v1.other-uid.9999999999.deadbeef';
      for (final link in [
        'http://2026-app.flutterkaigi.jp/x/$token',
        'https://2026-app.flutterkaigi.jp.evil.example/x/$token',
        'https://2026-app.flutterkaigi.jp@evil.example/x/$token',
        'https://user@2026-app.flutterkaigi.jp/x/$token',
        'https://2026-app.flutterkaigi.jp:8443/x/$token',
        'https:/x/$token',
        'https:abc',
        '$productionExchangeOrigin/x/$token/extra',
        '$productionExchangeOrigin/x/$token?redirect=elsewhere',
        '$productionExchangeOrigin/x/$token#fragment',
        '$productionExchangeOrigin/other/$token',
      ]) {
        expect(parseScannedExchangeToken(link), isNull, reason: link);
      }
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

  group('isExchangeTokenExpired', () {
    test('is false for a token whose embedded exp is in the future', () {
      final expSeconds = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
      expect(isExchangeTokenExpired('v1.other-uid.$expSeconds.deadbeef'), isFalse);
    });

    test('is true for a token whose embedded exp is in the past', () {
      final expSeconds = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
      expect(isExchangeTokenExpired('v1.other-uid.$expSeconds.deadbeef'), isTrue);
    });

    test('is false for a malformed token (deferred to server-side verification)', () {
      expect(isExchangeTokenExpired('not-a-token'), isFalse);
      expect(isExchangeTokenExpired('v1.other-uid.not-a-number.deadbeef'), isFalse);
    });
  });
}
