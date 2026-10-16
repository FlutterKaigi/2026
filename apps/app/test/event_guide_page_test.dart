import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/clock.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/event_guide/data/event_guide_seen_provider.dart';
import 'package:app/feature/event_guide/ui/page/event_guide_page.dart';
import 'package:app/feature/push_notification/data/push_notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_push_notification_repository.dart';

const _titles = [
  'FlutterKaigi 2026 へようこそ',
  'セッションをブックマーク',
  '参加者やスポンサーと交流',
  '2日目はクイズ大会',
];

void main() {
  late FakePushNotificationRepository pushNotifications;
  late SharedPreferences preferences;

  setUpAll(() async => AppLocale.en.build());
  setUp(() async {
    pushNotifications = FakePushNotificationRepository();
    SharedPreferences.setMockInitialValues(const {});
    preferences = await SharedPreferences.getInstance();
  });
  tearDown(() {
    pushNotifications.dispose();
    LocaleSettings.setLocaleSync(AppLocale.ja);
  });

  Future<GoRouter> pumpGuide(
    WidgetTester tester, {
    String initialLocation = '/info',
    AppLocale locale = AppLocale.ja,
    TextScaler textScaler = TextScaler.noScaling,
    DateTime? now,
  }) async {
    LocaleSettings.setLocaleSync(locale);
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/info',
          builder: (context, state) => const Scaffold(body: Text('event tab')),
        ),
        GoRoute(path: '/guide', builder: (context, state) => const EventGuidePage()),
        GoRoute(
          path: '/account/venue-events',
          builder: (context, state) => const Scaffold(body: Text('venue events hub')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            pushNotificationRepositoryProvider.overrideWithValue(pushNotifications),
            sharedPreferencesProvider.overrideWithValue(preferences),
            clockProvider.overrideWithValue(() => now ?? DateTime.utc(2026, 10, 15, 3)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: locale.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<bool Function()> openOverEventTab(WidgetTester tester, GoRouter router) async {
    var closed = false;
    unawaited(router.push<void>('/guide').then((_) => closed = true));
    await tester.pumpAndSettle();
    return () => closed;
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  String path(GoRouter router) => router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('pages through with next, back and swipes', (tester) async {
    await pumpGuide(tester, initialLocation: '/guide');
    final back = find.byTooltip('戻る');

    expect(find.text(_titles[0]), findsOneWidget);
    expect(back, findsNothing);

    await tapAndSettle(tester, find.text('次へ'));
    expect(find.text(_titles[1]), findsOneWidget);

    await tapAndSettle(tester, back);
    expect(find.text(_titles[0]), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(_titles[1]), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(_titles[0]), findsOneWidget);

    for (final title in _titles.skip(1)) {
      await tapAndSettle(tester, find.text('次へ'));
      expect(find.text(title), findsOneWidget);
      expect(back, findsOneWidget);
    }
    expect(find.text('次へ'), findsNothing);
    expect(find.text('スキップ'), findsNothing);
    expect(find.text('会場イベントに参加'), findsOneWidget);
    expect(find.text('閉じる'), findsOneWidget);
  });

  testWidgets('tells assistive technology which page is showing', (tester) async {
    await pumpGuide(tester, initialLocation: '/guide');

    for (var page = 1; page <= 4; page++) {
      if (page > 1) {
        await tapAndSettle(tester, find.text('次へ'));
      }
      expect(find.bySemanticsLabel('4ページ中$pageページ目'), findsOneWidget);
    }
  });

  testWidgets('keeps the illustrations out of the semantics tree', (tester) async {
    await pumpGuide(tester, initialLocation: '/guide');

    for (final text in ['ホール A', 'イベントタブ', '10月30日(金) 2日目']) {
      await tapAndSettle(tester, find.text('次へ'));
      expect(find.text(text), findsOneWidget);
      expect(find.bySemanticsLabel(text), findsNothing);
    }
  });

  testWidgets('skip closes the guide back to the screen that opened it', (tester) async {
    final router = await pumpGuide(tester);
    final closed = await openOverEventTab(tester, router);
    await tapAndSettle(tester, find.text('次へ'));

    await tapAndSettle(tester, find.text('スキップ'));

    expect(closed(), isTrue);
    expect(path(router), '/info');
    expect(find.text('event tab'), findsOneWidget);
  });

  testWidgets('close on the last page returns to the screen that opened it', (tester) async {
    final router = await pumpGuide(tester);
    final closed = await openOverEventTab(tester, router);
    for (var page = 1; page < 4; page++) {
      await tapAndSettle(tester, find.text('次へ'));
    }

    await tapAndSettle(tester, find.text('閉じる'));

    expect(closed(), isTrue);
    expect(path(router), '/info');
    expect(find.text('event tab'), findsOneWidget);
  });

  testWidgets('closes to the event tab when a link opened it', (tester) async {
    final router = await pumpGuide(tester, initialLocation: '/guide');

    await tapAndSettle(tester, find.text('スキップ'));

    expect(path(router), '/info');
    expect(find.text('event tab'), findsOneWidget);
  });

  testWidgets('hands over to the venue events hub when opened over the event tab', (tester) async {
    final router = await pumpGuide(tester);
    await openOverEventTab(tester, router);
    for (var page = 1; page < 4; page++) {
      await tapAndSettle(tester, find.text('次へ'));
    }

    await tapAndSettle(tester, find.text('会場イベントに参加'));

    expect(path(router), '/account/venue-events');
    expect(find.text('venue events hub'), findsOneWidget);
  });

  testWidgets('hands over to the venue events hub when a link opened it', (tester) async {
    final router = await pumpGuide(tester, initialLocation: '/guide');
    for (var page = 1; page < 4; page++) {
      await tapAndSettle(tester, find.text('次へ'));
    }

    await tapAndSettle(tester, find.text('会場イベントに参加'));

    expect(path(router), '/account/venue-events');
    expect(find.text('venue events hub'), findsOneWidget);
  });

  for (final (way, close) in <(String, Future<void> Function(WidgetTester, GoRouter))>[
    ('skip', (tester, router) => tapAndSettle(tester, find.text('スキップ'))),
    (
      'close',
      (tester, router) async {
        for (var page = 1; page < 4; page++) {
          await tapAndSettle(tester, find.text('次へ'));
        }
        await tapAndSettle(tester, find.text('閉じる'));
      },
    ),
    (
      'the venue events button',
      (tester, router) async {
        for (var page = 1; page < 4; page++) {
          await tapAndSettle(tester, find.text('次へ'));
        }
        await tapAndSettle(tester, find.text('会場イベントに参加'));
      },
    ),
    (
      'a navigation elsewhere',
      (tester, router) async {
        router.go('/account/venue-events');
        await tester.pumpAndSettle();
      },
    ),
  ]) {
    testWidgets('asks for the notification permission once it goes away through $way', (tester) async {
      final router = await pumpGuide(tester);
      await openOverEventTab(tester, router);
      expect(pushNotifications.permissionRequestCount, 0);

      await close(tester, router);

      expect(find.byType(EventGuidePage), findsNothing);
      expect(pushNotifications.permissionRequestCount, 1);
    });
  }

  testWidgets('asks for the notification permission only after the last of two guides goes', (tester) async {
    final router = await pumpGuide(tester);
    await openOverEventTab(tester, router);
    await openOverEventTab(tester, router);

    await tapAndSettle(tester, find.text('スキップ'));

    expect(find.byType(EventGuidePage), findsOneWidget);
    expect(pushNotifications.permissionRequestCount, 0);

    await tapAndSettle(tester, find.text('スキップ'));

    expect(find.byType(EventGuidePage), findsNothing);
    expect(pushNotifications.permissionRequestCount, 1);
  });

  testWidgets('counts as seen once it shows on the event days', (tester) async {
    await pumpGuide(tester, initialLocation: '/guide', now: DateTime.utc(2026, 10, 29, 1));

    expect(preferences.getBool(EventGuideSeenNotifier.preferencesKey), isTrue);
  });

  testWidgets('does not count as seen when it shows before the event days', (tester) async {
    await pumpGuide(tester, initialLocation: '/guide', now: DateTime.utc(2026, 10, 28, 20, 59));

    expect(find.byType(EventGuidePage), findsOneWidget);
    expect(preferences.getBool(EventGuideSeenNotifier.preferencesKey), isNull);
  });

  testWidgets('keeps the text of every page in view on a 320 x 568 screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpGuide(tester, initialLocation: '/guide');
    final translations = AppLocale.ja.translations.eventGuide;

    for (final (page, body) in [
      translations.welcome.body,
      translations.sessions.body,
      translations.venueEvents.body,
      translations.quiz.body,
    ].indexed) {
      if (page > 0) {
        await tapAndSettle(tester, find.text(translations.next));
      }
      final dots = find.bySemanticsLabel(translations.pageIndicator(page: page + 1, total: 4));
      expect(
        tester.getRect(find.text(body)).bottom,
        lessThanOrEqualTo(tester.getRect(dots).top),
        reason: 'page ${page + 1}',
      );
    }
  });

  for (final locale in AppLocale.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('lays out every page at 320 x 568 with ${scale}x text (${locale.languageCode})', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pumpGuide(tester, initialLocation: '/guide', locale: locale, textScaler: TextScaler.linear(scale));
        final translations = locale.translations;

        for (var page = 1; page <= 4; page++) {
          if (page > 1) {
            await tapAndSettle(tester, find.text(translations.eventGuide.next));
          }
          expect(tester.takeException(), isNull, reason: 'page $page');
        }
        await tapAndSettle(tester, find.text(translations.venueEvents.title));
        expect(find.text('venue events hub'), findsOneWidget);
      });
    }
  }
}
