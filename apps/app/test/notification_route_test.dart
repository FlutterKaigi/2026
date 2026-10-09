import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/push_notification/data/notification_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_remote_config_repository.dart';

const _actingLinks = [
  '/x/v1.other-uid.9999999999.deadbeef',
  '/s/abababababababababababababababababababababababababababababababab',
  '/account/support-lt/123456',
  '/sessions/../x/v1.other-uid.9999999999.deadbeef',
  '/news/./../s/abababababababababababababababababababababababababababababababab',
  r'/x\v1.other-uid.9999999999.deadbeef',
  '/%78/v1.other-uid.9999999999.deadbeef',
  '/account/support-lt/%31%32%33%34%35%36',
];

void main() {
  group('parseNotificationRoute', () {
    test('accepts in-app paths', () {
      for (final (raw, path) in [
        ('/news', '/news'),
        ('/sessions/abc', '/sessions/abc'),
        ('  /venue-map\n', '/venue-map'),
        ('/account/support-lt', '/account/support-lt'),
        ('/sessions/../news', '/news'),
        ('/sessions/%E6%97%A5%E6%9C%AC%E8%AA%9E', '/sessions/日本語'),
      ]) {
        expect(parseNotificationRoute(raw)?.location, Uri(path: path), reason: raw);
      }
    });

    test('rejects values that are not in-app paths', () {
      for (final raw in <Object?>[
        null,
        42,
        '',
        '   ',
        'news',
        'https://2026-app.flutterkaigi.jp/news',
        '//2026-app.flutterkaigi.jp/news',
        r'\\2026-app.flutterkaigi.jp\news',
        'javascript:alert(1)',
        '//user@2026-app.flutterkaigi.jp/news',
        '/news?from=push',
        '/news#top',
        '/news/',
        '/account//quiz',
      ]) {
        expect(parseNotificationRoute(raw), isNull, reason: '$raw');
      }
    });

    for (final raw in [
      '/sessions/%FF',
      '/news/%E9',
      '/sessions/%C0%AF',
      '/sessions/%ED%A0%80',
      '/sessions/%F4%90%80%80',
    ]) {
      test('rejects invalid UTF-8 in $raw without throwing', () {
        expect(parseNotificationRoute(raw), isNull);
      });
    }

    test('rejects links that act on the attendee as soon as they open', () {
      for (final raw in [..._actingLinks, '/x', '/s']) {
        expect(parseNotificationRoute(raw), isNull, reason: raw);
      }
    });

    test('compares routes by location', () {
      expect(parseNotificationRoute('/news'), parseNotificationRoute(' /news '));
      expect(parseNotificationRoute('/news').hashCode, parseNotificationRoute(' /news ').hashCode);
      expect(parseNotificationRoute('/news'), isNot(parseNotificationRoute('/sessions')));
    });
  });

  group('with the app router', () {
    late GoRouter router;

    setUp(() {
      final remoteConfig = FakeRemoteConfigRepository();
      final container = ProviderContainer(
        overrides: [remoteConfigRepositoryProvider.overrideWithValue(remoteConfig)],
      );
      router = container.read(routerProvider);
      addTearDown(() {
        router.dispose();
        container.dispose();
        remoteConfig.dispose();
        GoRouter.optionURLReflectsImperativeAPIs = false;
      });
    });

    test('every rejected acting link is a declared route', () {
      for (final raw in _actingLinks) {
        expect(
          router.configuration.findMatch(Uri.parse(raw)).isError,
          isFalse,
          reason: '$raw no longer opens a route: move its rejection in parseNotificationRoute to the renamed route',
        );
      }
    });

    test('accepted look-alikes of acting links open no route', () {
      for (final raw in ['/x%2Fv1.other-uid.9999999999.deadbeef', '/X/v1.other-uid.9999999999.deadbeef']) {
        final route = parseNotificationRoute(raw);
        expect(route, isNotNull, reason: raw);
        expect(router.configuration.findMatch(route!.location).isError, isTrue, reason: raw);
      }
    });
  });
}
