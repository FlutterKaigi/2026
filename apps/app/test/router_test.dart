import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/page/account_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_remote_config_repository.dart';

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

  group('event feature redirect', () {
    // go_router only evaluates `redirect` as part of the RouteInformation
    // parsing pipeline driven by a mounted `Router` widget, so these run as
    // `testWidgets` with the real router pumped into a `MaterialApp.router`
    // instead of calling `router.go` on a bare `GoRouter`. Every blocked
    // destination shows a sign-in prompt while signed out (see
    // `AuthenticatedBody` / `ExchangeAccessGate` / `QuizSignInRequiredView`),
    // so a signed-out `FakeAuthRepository` is enough to render them without
    // wiring up their other repositories.
    //
    // `routerProvider` must be watched from inside the widget tree (as
    // `app.dart` does with `ref.watch(routerProvider)`), not just
    // `container.read` from the test — Riverpod pauses a provider's stream
    // dependencies once it has no active listener of its own, which would
    // otherwise stop `remoteConfigUpdatesProvider` from ever notifying
    // `eventFeaturesEnabledProvider` of `setValue` calls.
    late FakeAuthRepository authRepository;
    late FakeRemoteConfigRepository remoteConfig;
    late SharedPreferences preferences;
    late ProviderContainer container;

    setUp(() async {
      LocaleSettings.setLocaleSync(AppLocale.ja);
      SharedPreferences.setMockInitialValues(const {});
      preferences = await SharedPreferences.getInstance();
      authRepository = FakeAuthRepository();
      remoteConfig = FakeRemoteConfigRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
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
    });

    /// Pumps the real app router (built through `routerProvider`, kept
    /// unpaused by watching it in the tree) and returns the live [GoRouter]
    /// instance for `.go()` calls.
    Future<GoRouter> pumpRouter(WidgetTester tester) async {
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
