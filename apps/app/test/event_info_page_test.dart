import 'dart:async';

import 'package:app/core/constants/app_links.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/i18n/strings_en.g.dart';
import 'package:app/core/provider/clock.dart';
import 'package:app/core/provider/package_info.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:app/core/router/router.dart' as app_router;
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/core/ui/widget/trademark_footer_widget.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/event/ui/page/event_info_page.dart';
import 'package:app/feature/event_guide/data/event_guide_seen_provider.dart';
import 'package:app/feature/event_guide/ui/page/event_guide_page.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:app/feature/push_notification/data/push_notification_provider.dart';
import 'package:app/feature/venue_events/ui/page/venue_events_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show Override;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_push_notification_repository.dart';
import 'fake_remote_config_repository.dart';
import 'fake_user_profile_repository.dart';

const _surveyUrl = 'https://forms.example.com/flutterkaigi-2026';

void main() {
  test('venue map link contains the exact venue name and address', () {
    final query = Uri.parse(AppLinks.venueMap).queryParameters['query'];

    expect(query, '浜松町コンベンションホール 東京都港区浜松町二丁目3番1号');
  });

  testWidgets('shows the 2026 event overview on a compact screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpEventInfoPage(tester);

    expect(find.text('イベント概要'), findsOneWidget);
    expect(find.text('最新のお知らせ'), findsOneWidget);
    expect(find.text('会って、話して、熱くなる。'), findsOneWidget);
    expect(find.text('〜Assemble〜'), findsOneWidget);
    expect(find.text('2026年10月29日(木) – 30日(金)'), findsOneWidget);
    expect(find.text('浜松町コンベンションホール'), findsOneWidget);
    expect(find.text('地図を見る'), findsOneWidget);
    expect(
      tester.getSize(find.widgetWithText(TextButton, '地図を見る')).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.text('チケットを購入'), findsNothing);
    expect(
      find.bySemanticsLabel('FlutterKaigi 2026 ロゴ'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.text('その他'), 500);
    await tester.pumpAndSettle();

    expect(find.text('クレジット'), findsOneWidget);
    expect(find.text('コントリビューター'), findsOneWidget);
    expect(find.text('その他'), findsOneWidget);
    expect(
      tester
          .getSize(
            find.ancestor(
              of: find.text('公式Webサイト'),
              matching: find.byType(ListTile),
            ),
          )
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.text('アプリ設定'), findsNothing);
    expect(find.byType(TrademarkFooterWidget), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('opens news from the event overview banner', (tester) async {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    addTearDown(() => GoRouter.optionURLReflectsImperativeAPIs = false);
    final router = GoRouter(
      initialLocation: '/info',
      routes: [
        GoRoute(
          path: '/info',
          builder: (context, state) => const EventInfoPage(),
        ),
        GoRoute(
          path: '/news',
          builder: (context, state) => const Scaffold(
            body: Text('news destination'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpEventInfoPage(tester, router: router);
    await tester.tap(find.text('最新のお知らせ'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/news');
    expect(find.text('news destination'), findsOneWidget);
  });

  testWidgets('shows the venue events banner above the news only while event features are enabled', (
    tester,
  ) async {
    final repository = FakeRemoteConfigRepository();
    await _pumpEventInfoPage(tester, remoteConfigRepository: repository);

    expect(find.text('会場イベントに参加'), findsOneWidget);
    expect(find.text('スタンプラリー・プロフィール交換など'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('会場イベントに参加')).dy,
      lessThan(tester.getTopLeft(find.text('最新のお知らせ')).dy),
    );

    repository.setValue(RemoteConfigKeys.eventFeaturesEnabled, false);
    await tester.pumpAndSettle();

    expect(find.text('会場イベントに参加'), findsNothing);
    expect(find.text('最新のお知らせ'), findsOneWidget);
  });

  testWidgets('switches to the venue events hub from its banner', (tester) async {
    final router = GoRouter(
      initialLocation: '/info',
      routes: [
        GoRoute(
          path: '/info',
          builder: (context, state) => const EventInfoPage(),
        ),
        GoRoute(
          path: '/account/venue-events',
          builder: (context, state) => const Scaffold(
            body: Text('venue events destination'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpEventInfoPage(tester, router: router);
    await tester.tap(find.text('会場イベントに参加'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/account/venue-events');
    expect(find.text('venue events destination'), findsOneWidget);
    // `go` replaces the event tab's stack instead of stacking the hub on it.
    expect(router.canPop(), isFalse);
  });

  testWidgets('opens the contributor list from the event overview', (
    tester,
  ) async {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    addTearDown(() => GoRouter.optionURLReflectsImperativeAPIs = false);
    final router = GoRouter(
      initialLocation: '/info',
      routes: [
        GoRoute(
          path: '/info',
          builder: (context, state) => const EventInfoPage(),
        ),
        GoRoute(
          path: '/contributors',
          builder: (context, state) => const Scaffold(
            body: Text('contributor destination'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpEventInfoPage(tester, router: router);
    await tester.scrollUntilVisible(find.text('コントリビューター'), 200);
    await tester.ensureVisible(find.text('コントリビューター'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('コントリビューター'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/contributors');
    expect(find.text('contributor destination'), findsOneWidget);
  });

  testWidgets('opens the OSS license list from the event overview', (
    tester,
  ) async {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    addTearDown(() => GoRouter.optionURLReflectsImperativeAPIs = false);
    final router = GoRouter(
      initialLocation: '/info',
      routes: [
        GoRoute(
          path: '/info',
          builder: (context, state) => const EventInfoPage(),
        ),
        GoRoute(
          path: '/licenses',
          builder: (context, state) => const Scaffold(
            body: Text('license destination'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpEventInfoPage(tester, router: router);
    await tester.scrollUntilVisible(find.text('OSSライセンス'), 200);
    await tester.ensureVisible(find.text('OSSライセンス'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OSSライセンス'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/licenses');
    expect(find.text('license destination'), findsOneWidget);
  });

  testWidgets('hides the survey card before the survey starts', (
    tester,
  ) async {
    await _pumpEventInfoPage(
      tester,
      clock: () => DateTime.utc(2026, 10, 30, 5, 59, 59),
      surveyUrl: _surveyUrl,
    );

    expect(find.text('アンケート協力のお願い'), findsNothing);
    expect(find.text('全体アンケートに回答する'), findsNothing);
  });

  testWidgets('shows the survey card and opens the configured survey URL', (
    tester,
  ) async {
    final openedUris = <Uri>[];

    await _pumpEventInfoPage(
      tester,
      clock: () => DateTime.utc(2026, 10, 30, 6),
      surveyUrl: _surveyUrl,
      externalUrlLauncher: (uri) async {
        openedUris.add(uri);
        return true;
      },
    );

    expect(find.text('アンケート協力のお願い'), findsOneWidget);
    expect(
      find.text('今後のFlutterKaigiをより良いイベントにするため、皆様のご意見をお聞かせください。'),
      findsOneWidget,
    );

    final button = find.text('全体アンケートに回答する');
    await tester.scrollUntilVisible(button, 200);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();

    expect(openedUris, [Uri.parse(_surveyUrl)]);
  });

  testWidgets('shows the English survey strings', (tester) async {
    await _pumpEventInfoPage(
      tester,
      locale: AppLocale.en,
      clock: () => DateTime.utc(2026, 10, 30, 6),
      surveyUrl: _surveyUrl,
    );

    expect(find.text('Survey Request'), findsOneWidget);
    expect(
      find.text('We would like to hear your opinions to make future FlutterKaigi events better.'),
      findsOneWidget,
    );
    expect(find.text('Answer the General Survey'), findsOneWidget);
  });

  testWidgets('shows the survey card when time passes while the page is open', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 10, 30, 5, 59);

    await _pumpEventInfoPage(tester, clock: () => now, surveyUrl: _surveyUrl);

    expect(find.text('アンケート協力のお願い'), findsNothing);

    now = DateTime.utc(2026, 10, 30, 6);
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    expect(find.text('アンケート協力のお願い'), findsOneWidget);
  });

  for (final (label, surveyUrl) in <(String, String?)>[
    ('unset', null),
    ('empty', ''),
    ('whitespace only', ' \t\n '),
    ('malformed', 'https://[invalid'),
    ('spaces in the host', 'https://not a host/survey'),
    ('without a host', 'https:///survey'),
    ('HTTP', 'http://forms.example.com/survey'),
    ('with credentials', 'https://user:password@forms.example.com/survey'),
  ]) {
    testWidgets('hides the entire survey card when the URL is $label', (
      tester,
    ) async {
      await _pumpEventInfoPage(
        tester,
        clock: () => DateTime.utc(2026, 10, 30, 6),
        surveyUrl: surveyUrl,
      );

      expect(find.text('アンケート協力のお願い'), findsNothing);
      expect(
        find.text('今後のFlutterKaigiをより良いイベントにするため、皆様のご意見をお聞かせください。'),
        findsNothing,
      );
      expect(find.text('全体アンケートに回答する'), findsNothing);
      expect(find.byIcon(Icons.assignment_outlined), findsNothing);
    });
  }

  testWidgets('applies survey URL changes while the page stays open', (
    tester,
  ) async {
    final repository = FakeRemoteConfigRepository();
    final openedUris = <Uri>[];
    const updatedUrl = 'https://forms.example.com/updated-survey';
    await _pumpEventInfoPage(
      tester,
      clock: () => DateTime.utc(2026, 10, 30, 6),
      remoteConfigRepository: repository,
      externalUrlLauncher: (uri) async {
        openedUris.add(uri);
        return true;
      },
    );
    expect(find.text('アンケート協力のお願い'), findsNothing);

    repository.setValue(RemoteConfigKeys.surveyUrl, _surveyUrl);
    await tester.pumpAndSettle();
    expect(find.text('アンケート協力のお願い'), findsOneWidget);

    final button = find.text('全体アンケートに回答する');
    await tester.scrollUntilVisible(button, 200);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    expect(openedUris, [Uri.parse(_surveyUrl)]);

    repository.setValue(RemoteConfigKeys.surveyUrl, updatedUrl);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    expect(openedUris, [Uri.parse(_surveyUrl), Uri.parse(updatedUrl)]);

    repository.setValue(RemoteConfigKeys.surveyUrl, '');
    await tester.pumpAndSettle();
    expect(find.text('アンケート協力のお願い'), findsNothing);
    expect(find.text('全体アンケートに回答する'), findsNothing);
  });

  testWidgets('opens Japanese docs links when Japanese is selected', (
    tester,
  ) async {
    _useCompactViewport(tester);
    final openedUris = <Uri>[];

    await _pumpEventInfoPage(
      tester,
      externalUrlLauncher: (uri) async {
        openedUris.add(uri);
        return true;
      },
    );

    await _tapDocsLinks(tester, locale: AppLocale.ja);

    expect(openedUris, [
      Uri.parse(AppLinks.codeOfConductJa),
      Uri.parse(AppLinks.privacyPolicyJa),
      Uri.parse(AppLinks.exclusionPolicyJa),
    ]);
  });

  testWidgets('opens English docs links when English is selected', (
    tester,
  ) async {
    _useCompactViewport(tester);
    final openedUris = <Uri>[];

    await _pumpEventInfoPage(
      tester,
      locale: AppLocale.en,
      externalUrlLauncher: (uri) async {
        openedUris.add(uri);
        return true;
      },
    );

    await _tapDocsLinks(tester, locale: AppLocale.en);

    expect(openedUris, [
      Uri.parse(AppLinks.codeOfConductEn),
      Uri.parse(AppLinks.privacyPolicyEn),
      Uri.parse(AppLinks.exclusionPolicyEn),
    ]);
  });

  group('day-of guide', () {
    final onDay1 = DateTime.utc(2026, 10, 29, 1);
    late FakePushNotificationRepository pushNotifications;

    setUp(() => pushNotifications = FakePushNotificationRepository());

    GoRouter guideRouter({String initialLocation = '/info', GoRouterRedirect? redirect}) {
      final router = GoRouter(
        initialLocation: initialLocation,
        redirect: redirect,
        routes: [
          GoRoute(
            path: '/info',
            builder: (context, state) => const EventInfoPage(),
            routes: [
              GoRoute(
                path: 'staff',
                builder: (context, state) => const Scaffold(body: Text('staff destination')),
              ),
            ],
          ),
          GoRoute(path: '/guide', builder: (context, state) => const EventGuidePage()),
          GoRoute(
            path: '/account',
            builder: (context, state) => const Scaffold(body: Text('account destination')),
          ),
          GoRoute(
            path: '/account/venue-events',
            builder: (context, state) => const Scaffold(body: Text('venue events destination')),
          ),
        ],
      );
      addTearDown(router.dispose);
      return router;
    }

    Future<void> resume(WidgetTester tester) async {
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    }

    final guide = find.byType(EventGuidePage, skipOffstage: false);

    Future<String?> slowToOpenGuide(BuildContext context, GoRouterState state) async {
      if (state.uri.path == '/guide') {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      return null;
    }

    testWidgets('opens by itself once on the event days and remembers it', (tester) async {
      final preferences = await _pumpEventInfoPage(
        tester,
        router: guideRouter(),
        clock: () => onDay1,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );

      expect(guide, findsOneWidget);
      expect(preferences.getBool(EventGuideSeenNotifier.preferencesKey), isTrue);

      await tester.tap(find.text('スキップ'));
      await tester.pumpAndSettle();
      expect(guide, findsNothing);
      expect(find.text('イベント概要'), findsOneWidget);

      await resume(tester);
      expect(guide, findsNothing);
    });

    testWidgets('stays closed once this device has shown it', (tester) async {
      await _pumpEventInfoPage(
        tester,
        router: guideRouter(),
        clock: () => onDay1,
        pushNotifications: pushNotifications,
      );

      expect(guide, findsNothing);
    });

    for (final (label, now) in [
      ('before 6:00 JST on day 1', DateTime.utc(2026, 10, 28, 20, 59, 59)),
      ('after day 2', DateTime.utc(2026, 10, 30, 15)),
    ]) {
      testWidgets('stays closed $label', (tester) async {
        await _pumpEventInfoPage(
          tester,
          router: guideRouter(),
          clock: () => now,
          pushNotifications: pushNotifications,
          guideSeen: false,
        );

        expect(guide, findsNothing);
      });
    }

    testWidgets('neither opens nor offers the guide while event features are off', (tester) async {
      await _pumpEventInfoPage(
        tester,
        router: guideRouter(),
        clock: () => onDay1,
        remoteConfigRepository: FakeRemoteConfigRepository(
          initialValues: {RemoteConfigKeys.eventFeaturesEnabled: false},
        ),
        pushNotifications: pushNotifications,
        guideSeen: false,
      );

      expect(guide, findsNothing);
      expect(find.byTooltip('当日ガイド'), findsNothing);
      expect(pushNotifications.permissionRequestCount, 1);
    });

    testWidgets('waits for the event tab when the app opens on a link', (tester) async {
      final router = guideRouter(initialLocation: '/account');
      await _pumpEventInfoPage(
        tester,
        router: router,
        clock: () => onDay1,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );
      await resume(tester);

      expect(guide, findsNothing);
      expect(pushNotifications.permissionRequestCount, 0);

      router.go('/info');
      await tester.pumpAndSettle();

      expect(guide, findsOneWidget);
    });

    testWidgets('waits while another page covers the event tab', (tester) async {
      final router = guideRouter(initialLocation: '/info/staff');
      await _pumpEventInfoPage(
        tester,
        router: router,
        clock: () => onDay1,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );
      await resume(tester);

      expect(find.text('staff destination'), findsOneWidget);
      expect(guide, findsNothing);
      expect(pushNotifications.permissionRequestCount, 0);

      router.pop();
      await tester.pumpAndSettle();
      await resume(tester);

      expect(guide, findsOneWidget);
    });

    testWidgets('waits while a page pushed over the event tab is in front', (tester) async {
      var now = DateTime.utc(2026, 10, 28, 11);
      final router = guideRouter();
      await _pumpEventInfoPage(
        tester,
        router: router,
        clock: () => now,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );
      unawaited(router.push<void>('/info/staff'));
      await tester.pumpAndSettle();

      now = onDay1;
      await resume(tester);

      expect(find.text('staff destination'), findsOneWidget);
      expect(guide, findsNothing);

      router.pop();
      await tester.pumpAndSettle();

      expect(guide, findsOneWidget);
    });

    testWidgets('opens when the app returns to the event tab on the event days', (tester) async {
      var now = DateTime.utc(2026, 10, 28, 11);
      await _pumpEventInfoPage(
        tester,
        router: guideRouter(),
        clock: () => now,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );
      expect(guide, findsNothing);

      now = onDay1;
      await resume(tester);

      expect(guide, findsOneWidget);
    });

    testWidgets('does not open a second guide when the app returns to the open guide', (tester) async {
      await _pumpEventInfoPage(
        tester,
        router: guideRouter(),
        clock: () => onDay1,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );

      await resume(tester);

      expect(guide, findsOneWidget);
    });

    testWidgets('asks for the notification permission only once the closing guide has gone', (tester) async {
      await _pumpEventInfoPage(
        tester,
        router: guideRouter(),
        clock: () => onDay1,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );
      expect(pushNotifications.permissionRequestCount, 0);

      await tester.tap(find.text('スキップ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(guide, findsOneWidget);
      expect(pushNotifications.permissionRequestCount, 0);

      await tester.pumpAndSettle();

      expect(guide, findsNothing);
      expect(pushNotifications.permissionRequestCount, 1);
    });

    testWidgets('waits for a guide that a link opens over the auto-opened one', (tester) async {
      final router = guideRouter();
      await _pumpEventInfoPage(
        tester,
        router: router,
        clock: () => onDay1,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );
      expect(guide, findsOneWidget);

      router.go('/guide');
      await tester.pumpAndSettle();

      expect(guide, findsOneWidget);
      expect(pushNotifications.permissionRequestCount, 0);

      await tester.tap(find.text('スキップ'));
      await tester.pumpAndSettle();

      expect(guide, findsNothing);
      expect(pushNotifications.permissionRequestCount, 1);
    });

    testWidgets('asks for the permission once when another navigation replaces the guide', (tester) async {
      final router = guideRouter();
      await _pumpEventInfoPage(
        tester,
        router: router,
        clock: () => onDay1,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );
      expect(guide, findsOneWidget);
      expect(pushNotifications.permissionRequestCount, 0);

      router.go('/account');
      await tester.pumpAndSettle();

      expect(guide, findsNothing);
      expect(pushNotifications.permissionRequestCount, 1);
    });

    testWidgets('asks for the permission after the guide hands over to the venue events', (tester) async {
      await _pumpEventInfoPage(
        tester,
        router: guideRouter(),
        clock: () => onDay1,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );
      for (var page = 1; page < 4; page++) {
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
      }
      expect(pushNotifications.permissionRequestCount, 0);

      await tester.tap(find.text('会場イベントに参加'));
      await tester.pumpAndSettle();

      expect(find.text('venue events destination'), findsOneWidget);
      expect(pushNotifications.permissionRequestCount, 1);
    });

    testWidgets('asks for the permission after the first frame when no guide is due, not on rebuilds', (
      tester,
    ) async {
      final remoteConfig = FakeRemoteConfigRepository();
      await _pumpEventInfoPage(
        tester,
        router: guideRouter(),
        remoteConfigRepository: remoteConfig,
        pushNotifications: pushNotifications,
      );
      expect(pushNotifications.permissionRequestCount, 1);

      remoteConfig.setValue(RemoteConfigKeys.surveyUrl, _surveyUrl);
      await tester.pumpAndSettle();

      expect(pushNotifications.permissionRequestCount, 1);
    });

    testWidgets('neither pushes a second guide nor asks for the permission while one is opening', (tester) async {
      await _pumpEventInfoPage(
        tester,
        router: guideRouter(redirect: slowToOpenGuide),
        clock: () => onDay1,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );
      expect(guide, findsNothing);

      await resume(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(guide, findsOneWidget);
      expect(pushNotifications.permissionRequestCount, 0);
    });

    testWidgets('opens the guide later when another navigation overtakes it while it opens', (tester) async {
      final router = guideRouter(redirect: slowToOpenGuide);
      await _pumpEventInfoPage(
        tester,
        router: router,
        clock: () => onDay1,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );

      unawaited(router.push<void>('/account'));
      await tester.pumpAndSettle();
      expect(find.text('account destination'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(guide, findsOneWidget);
    });

    testWidgets('opens when the user switches to the event tab on the event days', (tester) async {
      _useCompactViewport(tester);
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      final router = GoRouter(initialLocation: '/info', routes: app_router.$appRoutes);
      addTearDown(router.dispose);
      var now = DateTime.utc(2026, 10, 28, 11);
      await _pumpEventInfoPage(
        tester,
        router: router,
        clock: () => now,
        pushNotifications: pushNotifications,
        guideSeen: false,
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          appleSignInAvailabilityProvider.overrideWithValue(false),
          userProfileRepositoryProvider.overrideWithValue(FakeUserProfileRepository()),
        ],
      );
      Finder tab(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

      await tester.tap(tab('アカウント'));
      await tester.pumpAndSettle();
      now = onDay1;
      await resume(tester);
      expect(guide, findsNothing);

      await tester.tap(tab('イベント'));
      await tester.pumpAndSettle();

      expect(guide, findsOneWidget);
    });

    testWidgets('counts a guide opened by a link on the event days, so the event tab does not reopen it', (
      tester,
    ) async {
      final preferences = await _pumpEventInfoPage(
        tester,
        router: guideRouter(initialLocation: '/guide'),
        clock: () => onDay1,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );
      expect(preferences.getBool(EventGuideSeenNotifier.preferencesKey), isTrue);

      await tester.tap(find.text('スキップ'));
      await tester.pumpAndSettle();

      expect(find.text('イベント概要'), findsOneWidget);
      expect(guide, findsNothing);
    });

    testWidgets('does not count a guide opened by a link before the event days', (tester) async {
      var now = DateTime.utc(2026, 10, 28, 11);
      final preferences = await _pumpEventInfoPage(
        tester,
        router: guideRouter(initialLocation: '/guide'),
        clock: () => now,
        pushNotifications: pushNotifications,
        guideSeen: false,
      );
      await tester.tap(find.text('スキップ'));
      await tester.pumpAndSettle();
      expect(preferences.getBool(EventGuideSeenNotifier.preferencesKey), isFalse);
      expect(guide, findsNothing);

      now = onDay1;
      await resume(tester);

      expect(guide, findsOneWidget);
    });

    testWidgets('opens from the help button', (tester) async {
      await _pumpEventInfoPage(tester, router: guideRouter(), pushNotifications: pushNotifications);

      await tester.tap(find.byTooltip('当日ガイド'));
      await tester.pumpAndSettle();

      expect(guide, findsOneWidget);
    });

    testWidgets('covers the tabs and hands over to the venue events hub on the app routes', (tester) async {
      _useCompactViewport(tester);
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      final router = GoRouter(initialLocation: '/info', routes: app_router.$appRoutes);
      addTearDown(router.dispose);
      await _pumpEventInfoPage(
        tester,
        router: router,
        clock: () => onDay1,
        pushNotifications: pushNotifications,
        guideSeen: false,
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          appleSignInAvailabilityProvider.overrideWithValue(false),
        ],
      );

      expect(guide, findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      for (var page = 1; page < 4; page++) {
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('会場イベントに参加'));
      await tester.pumpAndSettle();

      expect(guide, findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(VenueEventsPage), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/account/venue-events');
      expect(pushNotifications.permissionRequestCount, 1);
    });
  });
}

void _useCompactViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<SharedPreferences> _pumpEventInfoPage(
  WidgetTester tester, {
  GoRouter? router,
  AppLocale locale = AppLocale.ja,
  ExternalUrlLauncher? externalUrlLauncher,
  Clock? clock,
  String? surveyUrl,
  FakeRemoteConfigRepository? remoteConfigRepository,
  FakePushNotificationRepository? pushNotifications,
  bool guideSeen = true,
  List<Override> overrides = const [],
}) async {
  final repository =
      remoteConfigRepository ??
      FakeRemoteConfigRepository(
        initialValues: {
          if (surveyUrl != null) RemoteConfigKeys.surveyUrl: surveyUrl,
        },
      );
  addTearDown(repository.dispose);
  final notifications = pushNotifications ?? FakePushNotificationRepository();
  addTearDown(notifications.dispose);
  final appRouter =
      router ??
      GoRouter(
        initialLocation: '/info',
        routes: [
          GoRoute(
            path: '/info',
            builder: (context, state) => EventInfoPage(externalUrlLauncher: externalUrlLauncher),
          ),
        ],
      );
  if (router == null) {
    addTearDown(appRouter.dispose);
  }
  if (locale == AppLocale.en) {
    // The English strings are deferred in production, but Flutter's test VM
    // cannot complete that load. Register them directly for widget tests.
    LocaleSettings.instance.translationMap[locale] ??= TranslationsEn();
  }
  LocaleSettings.setLocaleSync(locale);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.ja));
  SharedPreferences.setMockInitialValues({
    'app_locale': locale.languageCode,
    EventGuideSeenNotifier.preferencesKey: guideSeen,
  });
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          remoteConfigRepositoryProvider.overrideWithValue(repository),
          sharedPreferencesProvider.overrideWithValue(preferences),
          pushNotificationRepositoryProvider.overrideWithValue(notifications),
          packageInfoProvider.overrideWithValue(
            AsyncData(
              PackageInfo(
                appName: 'FlutterKaigi 2026',
                packageName: 'jp.flutterkaigi.conf2026',
                version: '1.2.3',
                buildNumber: '45',
              ),
            ),
          ),
          if (clock != null) clockProvider.overrideWithValue(clock),
          ...overrides,
        ],
        child: MaterialApp.router(
          routerConfig: appRouter,
          locale: locale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return preferences;
}

Future<void> _tapDocsLinks(
  WidgetTester tester, {
  required AppLocale locale,
}) async {
  final labels = switch (locale) {
    AppLocale.ja => [
      '行動規範',
      'プライバシーポリシー',
      '反社会的勢力排除に関する基本方針',
    ],
    AppLocale.en => [
      'Code of Conduct',
      'Privacy Policy',
      'Exclusion of Anti-Social Forces',
    ],
  };

  for (final label in labels) {
    final tile = find.ancestor(
      of: find.text(label),
      matching: find.byType(ListTile),
    );
    await tester.scrollUntilVisible(tile, 500);
    await tester.pumpAndSettle();
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pump();
  }
}
