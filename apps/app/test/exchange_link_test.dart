import 'package:app/feature/exchange/data/exchange_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildExchangeQrUri', () {
    test('builds the /x/<token> link', () {
      expect(
        buildExchangeQrUri('v1.uid-1.9999999999.sig').toString(),
        'https://2026.flutterkaigi.jp/x/v1.uid-1.9999999999.sig',
      );
    });
  });

  group('parseScannedExchangeToken', () {
    test('parses a full exchange link', () {
      final result = parseScannedExchangeToken('https://2026.flutterkaigi.jp/x/v1.uid-1.9999999999.sig');
      expect(result?.token, 'v1.uid-1.9999999999.sig');
      expect(result?.uid, 'uid-1');
    });

    test('parses a bare token as a fallback', () {
      final result = parseScannedExchangeToken('v1.uid-1.9999999999.sig');
      expect(result?.token, 'v1.uid-1.9999999999.sig');
      expect(result?.uid, 'uid-1');
    });

    test('trims surrounding whitespace', () {
      final result = parseScannedExchangeToken('  v1.uid-1.9999999999.sig  ');
      expect(result?.uid, 'uid-1');
    });

    test('rejects an empty value', () {
      expect(parseScannedExchangeToken(''), isNull);
    });

    test('rejects a URL without an /x/ path segment', () {
      expect(parseScannedExchangeToken('https://2026.flutterkaigi.jp/'), isNull);
      expect(parseScannedExchangeToken('https://2026.flutterkaigi.jp/x'), isNull);
    });

    test('rejects an unrelated QR code (URL of another site)', () {
      expect(parseScannedExchangeToken('https://example.com/hello'), isNull);
    });

    test('rejects a token with the wrong version', () {
      expect(parseScannedExchangeToken('v2.uid-1.9999999999.sig'), isNull);
    });

    test('rejects a token with the wrong number of segments', () {
      expect(parseScannedExchangeToken('v1.uid-1.sig'), isNull);
    });

    test('rejects a token with an empty uid', () {
      expect(parseScannedExchangeToken('v1..9999999999.sig'), isNull);
    });

    test('rejects plain unrelated text', () {
      expect(parseScannedExchangeToken('hello world'), isNull);
    });
  });
}
