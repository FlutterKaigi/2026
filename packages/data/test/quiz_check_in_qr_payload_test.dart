import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const production = {productionAppOrigin};

  group('quizCheckInQrPayload', () {
    test('links to the event check-in under the selected origin', () {
      expect(
        quizCheckInQrPayload('event1', '123456', origin: productionAppOrigin),
        'https://2026-app.flutterkaigi.jp/account/quiz/event1/check-in/123456',
      );
      expect(
        quizCheckInQrPayload('event1', '123456', origin: stagingAppOrigin),
        '$stagingAppOrigin/account/quiz/event1/check-in/123456',
      );
    });

    test('is the bare code without an origin', () {
      expect(quizCheckInQrPayload('event1', '123456', origin: null), '123456');
    });
  });

  group('parseQuizCheckInQrPayload', () {
    test('round-trips a generated link with its event', () {
      final payload = quizCheckInQrPayload('event1', '123456', origin: productionAppOrigin);
      expect(parseQuizCheckInQrPayload(payload, allowedOrigins: production), (eventId: 'event1', code: '123456'));
    });

    test('accepts a bare code without an event in every environment and trims whitespace', () {
      expect(parseQuizCheckInQrPayload('123456', allowedOrigins: const {}), (eventId: null, code: '123456'));
      expect(parseQuizCheckInQrPayload(' 123456\n', allowedOrigins: production), (eventId: null, code: '123456'));
    });

    test('rejects a link from another environment', () {
      final stagingLink = quizCheckInQrPayload('event1', '123456', origin: stagingAppOrigin);
      final productionLink = quizCheckInQrPayload('event1', '123456', origin: productionAppOrigin);

      expect(parseQuizCheckInQrPayload(stagingLink, allowedOrigins: production), isNull);
      expect(parseQuizCheckInQrPayload(productionLink, allowedOrigins: const {stagingAppOrigin}), isNull);
      expect(parseQuizCheckInQrPayload(productionLink, allowedOrigins: const {}), isNull);
    });

    for (final (description, raw) in [
      ('http scheme', 'http://2026-app.flutterkaigi.jp/account/quiz/event1/check-in/123456'),
      ('user info', 'https://user@2026-app.flutterkaigi.jp/account/quiz/event1/check-in/123456'),
      ('a query', 'https://2026-app.flutterkaigi.jp/account/quiz/event1/check-in/123456?next=1'),
      ('a fragment', 'https://2026-app.flutterkaigi.jp/account/quiz/event1/check-in/123456#top'),
      ('an extra segment', 'https://2026-app.flutterkaigi.jp/account/quiz/event1/check-in/123456/extra'),
      ('a missing event', 'https://2026-app.flutterkaigi.jp/account/quiz/check-in/123456'),
      ('the event page itself', 'https://2026-app.flutterkaigi.jp/account/quiz/event1'),
      ('a Support LT link', 'https://2026-app.flutterkaigi.jp/account/support-lt/123456'),
      ('five digits', 'https://2026-app.flutterkaigi.jp/account/quiz/event1/check-in/12345'),
      ('full-width digits', '１２３４５６'),
      ('an empty value', ''),
    ]) {
      test('rejects $description', () {
        expect(parseQuizCheckInQrPayload(raw, allowedOrigins: production), isNull);
      });
    }
  });

  test('quizCheckInLinkPath names the event check-in route', () {
    expect(quizCheckInLinkPath('event1'), '/account/quiz/event1/check-in');
  });
}
