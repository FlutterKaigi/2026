import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const production = {productionAppOrigin};

  group('supportLtQrPayload', () {
    test('links to the registration page under the selected origin', () {
      expect(
        supportLtQrPayload('123456', origin: productionAppOrigin),
        'https://2026-app.flutterkaigi.jp/account/support-lt/123456',
      );
      expect(supportLtQrPayload('123456', origin: stagingAppOrigin), '$stagingAppOrigin/account/support-lt/123456');
    });

    test('is the bare code without an origin', () {
      expect(supportLtQrPayload('123456', origin: null), '123456');
    });
  });

  group('parseSupportLtQrPayload', () {
    test('round-trips a generated link, keeping leading zeros', () {
      for (final code in ['123456', '000042']) {
        final payload = supportLtQrPayload(code, origin: productionAppOrigin);
        expect(parseSupportLtQrPayload(payload, allowedOrigins: production), code);
      }
    });

    test('accepts a bare code in every environment and trims whitespace', () {
      expect(parseSupportLtQrPayload('123456', allowedOrigins: const {}), '123456');
      expect(parseSupportLtQrPayload(' 123456\n', allowedOrigins: production), '123456');
    });

    test('rejects a link from another environment', () {
      final stagingLink = supportLtQrPayload('123456', origin: stagingAppOrigin);
      final productionLink = supportLtQrPayload('123456', origin: productionAppOrigin);

      expect(parseSupportLtQrPayload(stagingLink, allowedOrigins: production), isNull);
      expect(parseSupportLtQrPayload(productionLink, allowedOrigins: const {stagingAppOrigin}), isNull);
      expect(parseSupportLtQrPayload(productionLink, allowedOrigins: const {}), isNull);
      expect(
        parseSupportLtQrPayload('https://2026.flutterkaigi.jp/account/support-lt/123456', allowedOrigins: production),
        isNull,
      );
    });

    for (final (description, raw) in [
      ('http scheme', 'http://2026-app.flutterkaigi.jp/account/support-lt/123456'),
      ('user info', 'https://user@2026-app.flutterkaigi.jp/account/support-lt/123456'),
      ('another port', 'https://2026-app.flutterkaigi.jp:8443/account/support-lt/123456'),
      ('a query', 'https://2026-app.flutterkaigi.jp/account/support-lt/123456?next=1'),
      ('an empty query', 'https://2026-app.flutterkaigi.jp/account/support-lt/123456?'),
      ('a fragment', 'https://2026-app.flutterkaigi.jp/account/support-lt/123456#top'),
      ('an empty fragment', 'https://2026-app.flutterkaigi.jp/account/support-lt/123456#'),
      ('a trailing slash', 'https://2026-app.flutterkaigi.jp/account/support-lt/123456/'),
      ('an extra segment', 'https://2026-app.flutterkaigi.jp/account/support-lt/123456/extra'),
      ('a missing code', 'https://2026-app.flutterkaigi.jp/account/support-lt/'),
      ('the registration page itself', 'https://2026-app.flutterkaigi.jp/account/support-lt'),
      ('another path', 'https://2026-app.flutterkaigi.jp/x/123456'),
      ('a percent-encoded separator', 'https://2026-app.flutterkaigi.jp/account/support-lt%2F123456'),
      ('five digits', 'https://2026-app.flutterkaigi.jp/account/support-lt/12345'),
      ('seven digits', '1234567'),
      ('full-width digits', '１２３４５６'),
      ('letters', 'abcdef'),
      ('a profile-exchange token', 'v1.other-uid.9999999999.deadbeef'),
      ('an empty value', ''),
    ]) {
      test('rejects $description', () {
        expect(parseSupportLtQrPayload(raw, allowedOrigins: production), isNull);
      });
    }
  });

  test('isSupportLtCode accepts exactly six ASCII digits', () {
    expect(isSupportLtCode('000000'), isTrue);
    expect(isSupportLtCode('12345'), isFalse);
    expect(isSupportLtCode('1234567'), isFalse);
    expect(isSupportLtCode(' 123456'), isFalse);
    expect(isSupportLtCode('１２３４５６'), isFalse);
  });
}
