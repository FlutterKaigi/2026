import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/clock.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:app/core/router/launch_route.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/not_found_page.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/page/account_page.dart';
import 'package:app/feature/auth/ui/page/email_sign_in_page.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/event/ui/page/event_info_page.dart';
import 'package:app/feature/event_guide/data/event_guide_seen_provider.dart';
import 'package:app/feature/event_guide/ui/page/event_guide_page.dart';
import 'package:app/feature/exchange/data/provider/pending_exchange_token_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/exchange/ui/page/exchange_share_link_page.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:app/feature/push_notification/data/push_notification_provider.dart';
import 'package:app/feature/settings/ui/page/settings_page.dart';
import 'package:app/feature/stamp_rally/data/stamp_rally_provider.dart';
import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
import 'package:app/feature/support_lt/ui/page/support_lt_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_profile_exchange_repository.dart';
import 'fake_push_notification_repository.dart';
import 'fake_remote_config_repository.dart';
import 'fake_stamp_rally_repository.dart';
import 'fake_support_lt_repository.dart';
import 'fake_user_profile_repository.dart';

// Synthetic versions of the Firebase and native Google callbacks on iOS.
const _firebaseAuthCallbackQuery = '?deep_link_id=https%3A%2F%2Fexample.firebaseapp.com%2F__%2Fauth%2Fcallback';
const _authCallbacks = [
  'app-1-000000000000-ios-0000000000000000000000://firebaseauth/link$_firebaseAuthCallbackQuery',
  'com.googleusercontent.apps.test-client://firebaseauth/link$_firebaseAuthCallbackQuery',
  'com.googleusercontent.apps.test-client:/oauth2callback?code=test-code&state=test-state',
];

final _beforeGuideWindow = DateTime.utc(2026, 10, 15, 3);

void main() {
  test('application router reflects pushed deep links in the web URL', () {
    GoRouter.optionURLReflectsImperativeAPIs = false;
    final remoteConfig = FakeRemoteConfigRepository();
    final container = ProviderContainer(
      overrides: [remoteConfigRepositoryProvider.overrideWithValue(remoteConfig)],
    );
    addTearDown(() {
      container.dispose();
      remoteConfig.dispose();
      GoRouter.optionURLReflectsImperativeAPIs = false;
    });

    final router = container.read(routerProvider);
    addTearDown(router.dispose);

    expect(GoRouter.optionURLReflectsImperativeAPIs, isTrue);
    expect(router.routeInformationProvider.value.uri.path, '/info');
    expect(const LicenseRoute().location, '/licenses');
    expect(
      const LicenseDetailRoute(packageName: 'foo bar').location,
      '/licenses/foo%20bar',
    );
    expect(const AccountRoute().location, '/account');
    expect(const EmailSignInRoute().location, '/account/email');
    expect(const EventGuideRoute().location, '/guide');
    expect(const VenueEventsRoute().location, '/account/venue-events');
    expect(const SupportLtRoute().location, '/account/support-lt');
    // 応援LTのQRコードが指すリンクは、生成側(`supportLtQrPayload`)と同じパスで解決する。
    expect(
      const SupportLtLinkRoute(code: '123456').location,
      Uri.parse(supportLtQrPayload('123456', origin: productionAppOrigin)).path,
    );
    expect(const ExchangeHomeRoute().location, '/account/exchange');
    expect(const ExchangeScanRoute().location, '/account/exchange/scan');
    expect(const ExchangeListRoute().location, '/account/exchange/list');
    expect(
      const ShareLinkRoute(token: 'v1.other-uid.9999999999.deadbeef').location,
      '/x/v1.other-uid.9999999999.deadbeef',
    );
  });

  group('application navigation', () {
    // go_router only evaluates `redirect` as part of the RouteInformation
    // parsing pipeline driven by a mounted `Router` widget, so these run as
    // `testWidgets` with the real router pumped into a `MaterialApp.router`
    // instead of calling `router.go` on a bare `GoRouter`. Auth callback tests
    // also send the platform navigation message received from native iOS.
    //
    // `routerProvider` must be watched from inside the widget tree (as
    // `app.dart` does with `ref.watch(routerProvider)`), not just
    // `container.read` from the test — Riverpod pauses a provider's stream
    // dependencies once it has no active listener of its own, which would
    // otherwise stop `remoteConfigUpdatesProvider` from ever notifying
    // `eventFeaturesEnabledProvider` of `setValue` calls.
    late FakeAuthRepository authRepository;
    late FakeRemoteConfigRepository remoteConfig;
    late FakeUserProfileRepository profileRepository;
    late FakeSupportLtRepository supportLtRepository;
    late FakeProfileExchangeRepository exchangeRepository;
    late FakeStampRallyRepository stampRallyRepository;
    late FakePushNotificationRepository pushNotifications;
    late SharedPreferences preferences;
    late DateTime now;
    late ProviderContainer container;

    setUp(() async {
      LocaleSettings.setLocaleSync(AppLocale.ja);
      SharedPreferences.setMockInitialValues(const {});
      preferences = await SharedPreferences.getInstance();
      now = _beforeGuideWindow;
      authRepository = FakeAuthRepository();
      remoteConfig = FakeRemoteConfigRepository();
      profileRepository = FakeUserProfileRepository();
      supportLtRepository = FakeSupportLtRepository();
      exchangeRepository = FakeProfileExchangeRepository();
      stampRallyRepository = FakeStampRallyRepository();
      pushNotifications = FakePushNotificationRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          userProfileRepositoryProvider.overrideWithValue(profileRepository),
          supportLtRepositoryProvider.overrideWithValue(supportLtRepository),
          profileExchangeRepositoryProvider.overrideWithValue(exchangeRepository),
          stampRallyRepositoryProvider.overrideWithValue(stampRallyRepository),
          remoteConfigRepositoryProvider.overrideWithValue(remoteConfig),
          sharedPreferencesProvider.overrideWithValue(preferences),
          pushNotificationRepositoryProvider.overrideWithValue(pushNotifications),
          clockProvider.overrideWithValue(() => now),
        ],
      );
    });

    tearDown(() {
      container.read(routerProvider).dispose();
      container.dispose();
      authRepository.dispose();
      remoteConfig.dispose();
      profileRepository.dispose();
      supportLtRepository.dispose();
      exchangeRepository.dispose();
      pushNotifications.dispose();
    });

    /// Pumps the real app router (built through `routerProvider`, kept
    /// unpaused by watching it in the tree) and returns the live [GoRouter]
    /// instance for `.go()` calls.
    Future<GoRouter> pumpRouter(WidgetTester tester, {Uri? launchRoute}) async {
      if (launchRoute != null) {
        // `main` が `LaunchRouteObserver` で受け取ったリンクを override で渡す
        // のと同じ形。`container` は setUp で作られるので、ここで差し替える。
        container.dispose();
        container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepository),
            userProfileRepositoryProvider.overrideWithValue(profileRepository),
            supportLtRepositoryProvider.overrideWithValue(supportLtRepository),
            profileExchangeRepositoryProvider.overrideWithValue(exchangeRepository),
            stampRallyRepositoryProvider.overrideWithValue(stampRallyRepository),
            remoteConfigRepositoryProvider.overrideWithValue(remoteConfig),
            sharedPreferencesProvider.overrideWithValue(preferences),
            pushNotificationRepositoryProvider.overrideWithValue(pushNotifications),
            clockProvider.overrideWithValue(() => now),
            launchRouteProvider.overrideWithValue(launchRoute),
          ],
        );
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TranslationProvider(
            child: Consumer(
              builder: (context, ref, _) => MaterialApp.router(
                routerConfig: ref.watch(routerProvider),
                locale: const Locale('ja'),
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container.read(routerProvider);
    }

    String currentPath(GoRouter router) => router.routeInformationProvider.value.uri.path;

    Future<void> sendPlatformUrl(WidgetTester tester, String location) async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/navigation',
        const JSONMethodCodec().encodeMethodCall(
          MethodCall('pushRouteInformation', {'location': location}),
        ),
        (_) {},
      );
      await tester.pumpAndSettle();
    }

    testWidgets('keeps the account page when an iOS auth callback arrives', (tester) async {
      final router = await pumpRouter(tester);
      router.go('/account');
      await tester.pumpAndSettle();

      for (final callback in _authCallbacks) {
        await sendPlatformUrl(tester, callback);

        expect(find.byType(NotFoundPage), findsNothing);
        expect(find.byType(AccountPage), findsOneWidget);
        expect(currentPath(router), '/account');
      }
    });

    for (final eventFeaturesEnabled in [true, false]) {
      testWidgets('keeps Google sign-in complete with event features enabled: $eventFeaturesEnabled', (tester) async {
        remoteConfig.setValue(RemoteConfigKeys.eventFeaturesEnabled, eventFeaturesEnabled);
        final router = await pumpRouter(tester);
        router.go('/account');
        await tester.pumpAndSettle();

        await tester.tap(find.bySemanticsLabel('Google でサインイン'));
        await tester.pumpAndSettle();
        expect(authRepository.calledMethods, ['signInWithGoogle']);
        expect(find.text('Google User'), findsOneWidget);
        expect(currentPath(router), '/account');
        expect(container.read(routerProvider), same(router));

        for (final callback in _authCallbacks) {
          await sendPlatformUrl(tester, callback);

          expect(find.byType(NotFoundPage), findsNothing);
          expect(find.text('Google User'), findsOneWidget);
          expect(currentPath(router), '/account');
        }
      });
    }

    testWidgets('preserves a pushed sign-in page and its back stack after the callback', (tester) async {
      final router = await pumpRouter(tester);
      router.go('/account');
      await tester.pumpAndSettle();
      unawaited(router.push<void>('/account/support-lt'));
      await tester.pumpAndSettle();
      final previousConfiguration = router.routerDelegate.currentConfiguration;

      for (final callback in _authCallbacks) {
        await sendPlatformUrl(tester, callback);

        expect(find.byType(NotFoundPage), findsNothing);
        expect(find.byType(SupportLtPage), findsOneWidget);
        expect(router.routerDelegate.currentConfiguration, same(previousConfiguration));
        expect(currentPath(router), '/account/support-lt');
        expect(router.canPop(), isTrue);
      }

      // The auth stream may finish after the platform delivers the callback.
      await tester.tap(find.bySemanticsLabel('Google でサインイン'));
      await tester.pumpAndSettle();
      expect(authRepository.currentUser, isNotNull);
      expect(find.byType(SupportLtPage), findsOneWidget);
      expect(find.bySemanticsLabel('Google でサインイン'), findsNothing);

      router.pop();
      await tester.pumpAndSettle();
      expect(currentPath(router), '/account');
      expect(find.text('Google User'), findsOneWidget);
    });

    for (final callback in _authCallbacks) {
      testWidgets(
        'opens the account page on a cold start from ${Uri.parse(callback).scheme}${Uri.parse(callback).path}',
        (tester) async {
          tester.binding.platformDispatcher.defaultRouteNameTestValue = callback;
          addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);

          final router = await pumpRouter(tester);

          expect(find.byType(NotFoundPage), findsNothing);
          expect(find.byType(AccountPage), findsOneWidget);
          expect(currentPath(router), '/account');
        },
      );
    }

    testWidgets('opens the event info page when the app-host root URL arrives as a universal link', (
      tester,
    ) async {
      final router = await pumpRouter(tester);
      router.go('/account');
      await tester.pumpAndSettle();

      for (final location in [
        'https://2026-app.flutterkaigi.jp/',
        'https://2026-app.flutterkaigi.jp',
        'https://2026-app.flutterkaigi.jp/?utm_source=qr',
        '/',
      ]) {
        await sendPlatformUrl(tester, location);

        expect(find.byType(NotFoundPage), findsNothing, reason: location);
        expect(find.byType(EventInfoPage), findsOneWidget, reason: location);
        expect(currentPath(router), '/info', reason: location);
      }
    });

    testWidgets('opens the event info page on a cold start from the app-host root URL', (tester) async {
      tester.binding.platformDispatcher.defaultRouteNameTestValue = 'https://2026-app.flutterkaigi.jp/';
      addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);

      final router = await pumpRouter(tester);

      expect(find.byType(NotFoundPage), findsNothing);
      expect(find.byType(EventInfoPage), findsOneWidget);
      expect(currentPath(router), '/info');
    });

    testWidgets('starts on the share link an iOS cold start delivered before the tree was up', (tester) async {
      // iOS はリンクを最初のフレーム後に push で渡すので、プラットフォームの
      // 初期ルートは `/` のまま。`LaunchRouteObserver` が受けた値の方を使う。
      final router = await pumpRouter(
        tester,
        launchRoute: Uri.parse('https://2026-app.flutterkaigi.jp/x/v1.other-uid.9999999999.deadbeef'),
      );

      expect(find.byType(NotFoundPage), findsNothing);
      expect(find.byType(ExchangeShareLinkPage), findsOneWidget);
      expect(currentPath(router), '/x/v1.other-uid.9999999999.deadbeef');
    });

    testWidgets('starts on the event info page when the launch link is the app-host root URL', (tester) async {
      final router = await pumpRouter(tester, launchRoute: Uri.parse('https://2026-app.flutterkaigi.jp/'));

      expect(find.byType(NotFoundPage), findsNothing);
      expect(find.byType(EventInfoPage), findsOneWidget);
      expect(currentPath(router), '/info');
    });

    testWidgets('starts on the path-only route of the notification tap that launched the app', (tester) async {
      final router = await pumpRouter(tester, launchRoute: Uri(path: '/settings'));

      expect(find.byType(NotFoundPage), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(currentPath(router), '/settings');
    });

    testWidgets('continues to route universal links and report unrelated unknown URLs', (tester) async {
      final router = await pumpRouter(tester);
      await sendPlatformUrl(tester, 'https://2026.flutterkaigi.jp/x/v1.other-uid.9999999999.deadbeef');

      expect(find.byType(ExchangeShareLinkPage), findsOneWidget);
      expect(find.byType(NotFoundPage), findsNothing);
      expect(currentPath(router), '/x/v1.other-uid.9999999999.deadbeef');

      for (final location in [
        'https://2026.flutterkaigi.jp/link',
        'https://firebaseauth/link',
        'unrelated://firebaseauth/link',
        'com.googleusercontent.apps.test-client://firebaseauth/unknown',
        'com.googleusercontent.apps.test-client://unrelated/link',
        'com.googleusercontent.apps.test-client://unrelated/oauth2callback',
        'com.googleusercontent.apps.test-client:/oauth2callback/unknown',
        'com.googleusercontent.apps.test-client:/oauthredirect',
        'app-1-test:/oauth2callback',
        'unrelated:/oauth2callback',
        'https://example.com/oauth2callback',
      ]) {
        await sendPlatformUrl(tester, location);

        expect(find.byType(NotFoundPage), findsOneWidget, reason: location);
        expect(router.routeInformationProvider.value.uri, Uri.parse(location));
      }
    });

    testWidgets('redirects every blocked event-feature destination to /account when the flag is false', (
      tester,
    ) async {
      remoteConfig.setValue(RemoteConfigKeys.eventFeaturesEnabled, false);
      final router = await pumpRouter(tester);

      for (final location in <String>[
        '/account/venue-events',
        '/account/missions',
        '/account/quiz',
        '/account/quiz/some-event',
        '/account/support-lt',
        '/account/support-lt/123456',
        '/account/exchange',
        '/account/exchange/scan',
        '/account/exchange/list',
        '/account/sns-post',
        '/account/stamp-rally',
        '/account/stamp-rally/scan',
        // プロフィール交換・スタンプラリーのリンクも塞ぐ。
        '/x/v1.other-uid.9999999999.deadbeef',
        '/s/abababababababababababababababababababababababababababababababab',
      ]) {
        router.go(location);
        await tester.pumpAndSettle();

        expect(currentPath(router), '/account', reason: '$location should redirect to /account');
        expect(find.byType(AccountPage), findsOneWidget);
      }
    });

    testWidgets('does not redirect blocked destinations when the flag is true', (tester) async {
      final router = await pumpRouter(tester);

      for (final location in <String>[
        '/account/venue-events',
        '/account/missions',
        '/account/quiz',
        '/account/support-lt',
        '/account/support-lt/123456',
        '/account/exchange',
        '/account/sns-post',
        '/account/stamp-rally',
        '/x/v1.other-uid.9999999999.deadbeef',
        '/s/abababababababababababababababababababababababababababababababab',
      ]) {
        router.go(location);
        await tester.pumpAndSettle();

        expect(currentPath(router), location);
      }
    });

    testWidgets('opens a Support LT QR code link on the registration page above the account page', (tester) async {
      final router = await pumpRouter(tester);

      await sendPlatformUrl(tester, '/account/support-lt/123456');

      expect(find.byType(SupportLtPage), findsOneWidget);
      expect(tester.widget<SupportLtPage>(find.byType(SupportLtPage)).linkCode, '123456');
      expect(currentPath(router), '/account/support-lt/123456');
      // サインイン前は登録を送信しない。
      expect(supportLtRepository.submittedCodes, isEmpty);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(AccountPage), findsOneWidget);
      expect(currentPath(router), '/account');
    });

    testWidgets('leaves unrelated destinations untouched when the flag is false', (tester) async {
      remoteConfig.setValue(RemoteConfigKeys.eventFeaturesEnabled, false);
      final router = await pumpRouter(tester);

      router.go('/account/profile');
      await tester.pumpAndSettle();
      expect(currentPath(router), '/account/profile');

      // `/x` の前方一致で `/xyz` まで巻き込まないこと(宣言のない
      // パスなので NotFoundPage が出るが、リダイレクトはされない)。
      router.go('/xyz');
      await tester.pumpAndSettle();
      expect(currentPath(router), '/xyz');
    });

    testWidgets('sends the day-of guide to the event tab when the flag is false', (tester) async {
      remoteConfig.setValue(RemoteConfigKeys.eventFeaturesEnabled, false);
      final router = await pumpRouter(tester);
      router.go('/account');
      await tester.pumpAndSettle();

      router.go('/guide');
      await tester.pumpAndSettle();

      expect(currentPath(router), '/info');
      expect(find.byType(EventInfoPage), findsOneWidget);
      expect(find.byType(EventGuidePage), findsNothing);
    });

    testWidgets('starts on the event tab when the app opens on a day-of guide link with the flag false', (
      tester,
    ) async {
      now = DateTime.utc(2026, 10, 29, 1);
      remoteConfig.setValue(RemoteConfigKeys.eventFeaturesEnabled, false);
      final router = await pumpRouter(tester, launchRoute: Uri(path: '/guide'));

      expect(currentPath(router), '/info');
      expect(find.byType(EventGuidePage), findsNothing);
      expect(preferences.getBool(EventGuideSeenNotifier.preferencesKey), isNull);
    });

    group('email sign-in', () {
      Future<void> signInWithEmail(WidgetTester tester) async {
        await tester.enterText(find.byType(TextFormField).at(0), 'attendee@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');
        await tester.tap(find.text('サインイン'));
        await tester.pumpAndSettle();
      }

      String futureExchangeToken() {
        final expSeconds = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
        return 'v1.other-uid.$expSeconds.deadbeef';
      }

      Future<void> openTab(WidgetTester tester, String label) async {
        await tester.tap(
          find.descendant(
            of: find.byWidgetPredicate((widget) => widget is NavigationBar || widget is NavigationRail),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
      }

      /// Submits the email form opened from the share link, and leaves the
      /// sign-in pending until the returned completer completes.
      Future<Completer<void>> holdEmailSignInFromShareLink(WidgetTester tester, GoRouter router, String token) async {
        router.go('/x/$token');
        await tester.pumpAndSettle();
        await tester.tap(find.text('メールアドレスでサインイン'));
        await tester.pumpAndSettle();
        final pending = authRepository.pendingAction = Completer<void>();
        await tester.enterText(find.byType(TextFormField).at(0), 'attendee@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');
        await tester.tap(find.text('サインイン'));
        await tester.pump();
        return pending;
      }

      testWidgets('comes back to the share link, which completes the exchange there', (tester) async {
        await profileRepository.save(
          UserProfile(
            id: 'fake-uid',
            displayName: 'Attendee',
            countryOrRegion: 'JP',
            createdAt: DateTime.utc(2026, 8),
            updatedAt: DateTime.utc(2026, 8),
          ),
        );
        final token = futureExchangeToken();
        final router = await pumpRouter(tester);
        router.go('/x/$token');
        await tester.pumpAndSettle();

        await tester.tap(find.text('メールアドレスでサインイン'));
        await tester.pumpAndSettle();
        expect(find.byType(EmailSignInPage), findsOneWidget);
        await signInWithEmail(tester);

        expect(currentPath(router), '/x/$token');
        expect(find.text('プロフィールを交換しました'), findsOneWidget);
        expect(exchangeRepository.createCalls, [(uid: 'fake-uid', otherUid: 'other-uid', token: token)]);
        expect(find.byType(AccountPage, skipOffstage: false), findsNothing);
      });

      testWidgets('goes back from the email page to the share link with its token still queued', (tester) async {
        final token = futureExchangeToken();
        final router = await pumpRouter(tester);
        router.go('/x/$token');
        await tester.pumpAndSettle();

        await tester.tap(find.text('メールアドレスでサインイン'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButtonIcon));
        await tester.pumpAndSettle();

        expect(currentPath(router), '/x/$token');
        expect(find.byType(SignInCard), findsOneWidget);
        expect(container.read(pendingExchangeTokenProvider), (uid: null, token: token));
        expect(find.byType(AccountPage, skipOffstage: false), findsNothing);
      });

      testWidgets('comes back to the stamp rally link, which scans the code there', (tester) async {
        stampRallyRepository.scanResult = StampRallyThanksCardResult(
          alreadyRedeemed: false,
          redeemedAt: DateTime.utc(2026, 10, 30, 5),
        );
        final token = 'ab' * 32;
        final router = await pumpRouter(tester);
        router.go('/s/$token');
        await tester.pumpAndSettle();

        await tester.tap(find.text('メールアドレスでサインイン'));
        await tester.pumpAndSettle();
        await signInWithEmail(tester);

        expect(currentPath(router), '/s/$token');
        expect(find.text('クレーンゲームに挑戦できます'), findsOneWidget);
        expect(stampRallyRepository.scannedTokens, [token]);
        expect(find.byType(AccountPage, skipOffstage: false), findsNothing);
      });

      testWidgets('leaves the page pushed on another tab alone when a held email sign-in finishes', (tester) async {
        final token = futureExchangeToken();
        final router = await pumpRouter(tester);
        final signIn = await holdEmailSignInFromShareLink(tester, router, token);

        await openTab(tester, 'イベント');
        unawaited(router.push<void>('/licenses'));
        await tester.pumpAndSettle();
        signIn.complete();
        await tester.pumpAndSettle();

        expect(authRepository.currentUser, isNotNull);
        expect(currentPath(router), '/licenses');
        expect(router.canPop(), isTrue);

        // The email page waits on the account tab, and its back arrow returns
        // to the link, now signed in.
        await openTab(tester, 'アカウント');
        expect(currentPath(router), '/account/email');
        await tester.tap(find.byType(BackButtonIcon));
        await tester.pumpAndSettle();
        expect(currentPath(router), '/x/$token');
        expect(find.text('プロフィールを作成すると相手とプロフィールを交換できます'), findsOneWidget);
      });

      testWidgets("stays on another tab's root page when a held email sign-in finishes", (tester) async {
        final router = await pumpRouter(tester);
        final signIn = await holdEmailSignInFromShareLink(tester, router, futureExchangeToken());

        await openTab(tester, 'イベント');
        signIn.complete();
        await tester.pumpAndSettle();

        expect(authRepository.currentUser, isNotNull);
        expect(currentPath(router), '/info');
        expect(find.byType(EventInfoPage), findsOneWidget);
      });

      testWidgets('lands on the account tab when the email page was opened by URL', (tester) async {
        final router = await pumpRouter(tester);
        router.go('/account/email');
        await tester.pumpAndSettle();

        await signInWithEmail(tester);

        expect(currentPath(router), '/account');
        expect(find.byType(EmailSignInPage), findsNothing);
        expect(find.byType(AccountPage), findsOneWidget);
      });
    });

    testWidgets('redirects away as soon as the flag flips false while the destination is open', (tester) async {
      final router = await pumpRouter(tester);

      router.go('/account/missions');
      await tester.pumpAndSettle();
      expect(currentPath(router), '/account/missions');

      remoteConfig.setValue(RemoteConfigKeys.eventFeaturesEnabled, false);
      await tester.pumpAndSettle();

      expect(currentPath(router), '/account');
    });
  });
}
