import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:app/core/router/launch_route.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/not_found_page.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/page/account_page.dart';
import 'package:app/feature/event/ui/page/event_info_page.dart';
import 'package:app/feature/exchange/ui/page/exchange_share_link_page.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
import 'package:app/feature/support_lt/ui/page/support_lt_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_remote_config_repository.dart';
import 'fake_support_lt_repository.dart';
import 'fake_user_profile_repository.dart';

// Synthetic versions of the two callback schemes configured for iOS builds.
const _firebaseAuthCallbackQuery = '?deep_link_id=https%3A%2F%2Fexample.firebaseapp.com%2F__%2Fauth%2Fcallback';
const _firebaseAuthCallbacks = [
  'app-1-000000000000-ios-0000000000000000000000://firebaseauth/link$_firebaseAuthCallbackQuery',
  'com.googleusercontent.apps.test-client://firebaseauth/link$_firebaseAuthCallbackQuery',
];

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
    expect(const SupportLtRoute().location, '/account/support-lt');
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
    late SharedPreferences preferences;
    late ProviderContainer container;

    setUp(() async {
      LocaleSettings.setLocaleSync(AppLocale.ja);
      SharedPreferences.setMockInitialValues(const {});
      preferences = await SharedPreferences.getInstance();
      authRepository = FakeAuthRepository();
      remoteConfig = FakeRemoteConfigRepository();
      profileRepository = FakeUserProfileRepository();
      supportLtRepository = FakeSupportLtRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          userProfileRepositoryProvider.overrideWithValue(profileRepository),
          supportLtRepositoryProvider.overrideWithValue(supportLtRepository),
          remoteConfigRepositoryProvider.overrideWithValue(remoteConfig),
          sharedPreferencesProvider.overrideWithValue(preferences),
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
            remoteConfigRepositoryProvider.overrideWithValue(remoteConfig),
            sharedPreferencesProvider.overrideWithValue(preferences),
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

    testWidgets('keeps the account page when an iOS Firebase Auth callback arrives', (tester) async {
      final router = await pumpRouter(tester);
      router.go('/account');
      await tester.pumpAndSettle();

      await sendPlatformUrl(tester, _firebaseAuthCallbacks.first);

      expect(find.byType(NotFoundPage), findsNothing);
      expect(find.byType(AccountPage), findsOneWidget);
      expect(currentPath(router), '/account');
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

        for (final callback in _firebaseAuthCallbacks) {
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

      for (final callback in _firebaseAuthCallbacks) {
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

    for (final callback in _firebaseAuthCallbacks) {
      testWidgets('opens the account page on a cold start from ${Uri.parse(callback).scheme}', (tester) async {
        tester.binding.platformDispatcher.defaultRouteNameTestValue = callback;
        addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);

        final router = await pumpRouter(tester);

        expect(find.byType(NotFoundPage), findsNothing);
        expect(find.byType(AccountPage), findsOneWidget);
        expect(currentPath(router), '/account');
      });
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
        '/account/missions',
        '/account/quiz',
        '/account/quiz/some-event',
        '/account/support-lt',
        '/account/exchange',
        '/account/exchange/scan',
        '/account/exchange/list',
        '/account/sns-post',
        // プロフィール交換のシェアリンクも塞ぐ。
        '/x/v1.other-uid.9999999999.deadbeef',
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
        '/account/missions',
        '/account/quiz',
        '/account/support-lt',
        '/account/exchange',
        '/account/sns-post',
        '/x/v1.other-uid.9999999999.deadbeef',
      ]) {
        router.go(location);
        await tester.pumpAndSettle();

        expect(currentPath(router), location);
      }
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
