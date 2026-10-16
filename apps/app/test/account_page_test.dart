import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/environment.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:app/core/router/router.dart' as app_router;
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/page/account_page.dart';
import 'package:app/feature/auth/ui/widget/apple_sign_in_button.dart';
import 'package:app/feature/auth/ui/widget/google_sign_in_button.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/exchange/data/exchange_code.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:app/feature/exchange/data/provider/pending_exchange_token_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:app/feature/profile/ui/widget/country_flag_widget.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/page/quiz_event_list_page.dart';
import 'package:app/feature/quiz/ui/page/quiz_page.dart';
import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
import 'package:data/data.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_profile_exchange_repository.dart';
import 'fake_remote_config_repository.dart';
import 'fake_support_lt_repository.dart';
import 'fake_user_profile_repository.dart';

void main() {
  Widget buildSubject(
    FakeAuthRepository repository, {
    required SharedPreferences preferences,
    FakeUserProfileRepository? profileRepository,
    FakeSupportLtRepository? supportLtRepository,
    QuizEventRepository? quizRepository,
    GoRouter? router,
    ExchangeCodeCacheRepository? codeCache,
    FakeProfileExchangeRepository? exchangeRepository,
    String? pendingExchangeToken,
    String? pendingExchangeTokenUid,
    Flavor flavor = Flavor.production,
    bool? showsAppleSignIn = false,
    ValueNotifier<bool>? showsAccountPage,
    FakeRemoteConfigRepository? remoteConfigRepository,
  }) => TranslationProvider(
    child: ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        remoteConfigRepositoryProvider.overrideWith((ref) {
          final config = remoteConfigRepository ?? FakeRemoteConfigRepository();
          if (remoteConfigRepository == null) {
            ref.onDispose(config.dispose);
          }
          return config;
        }),
        if (quizRepository != null) quizEventRepositoryProvider.overrideWithValue(quizRepository),
        userProfileRepositoryProvider.overrideWithValue(profileRepository ?? FakeUserProfileRepository()),
        supportLtRepositoryProvider.overrideWith((ref) {
          final repository = supportLtRepository ?? FakeSupportLtRepository();
          if (supportLtRepository == null) {
            ref.onDispose(repository.dispose);
          }
          return repository;
        }),
        if (showsAppleSignIn != null) appleSignInAvailabilityProvider.overrideWithValue(showsAppleSignIn),
        sharedPreferencesProvider.overrideWithValue(preferences),
        if (codeCache != null) exchangeCodeCacheRepositoryProvider.overrideWithValue(codeCache),
        if (exchangeRepository != null) profileExchangeRepositoryProvider.overrideWithValue(exchangeRepository),
        if (pendingExchangeToken != null)
          pendingExchangeTokenProvider.overrideWith(
            () => _SeededPendingExchangeTokenNotifier((uid: pendingExchangeTokenUid, token: pendingExchangeToken)),
          ),
        environmentProvider.overrideWithValue(
          Environment(
            appIdSuffix: '',
            appName: 'FlutterKaigi 2026',
            flavor: flavor,
            firebaseProjectId: 'test-project',
            firestoreEmulatorHost: 'localhost:8080',
            androidFirestoreEmulatorHost: '10.0.2.2:8080',
          ),
        ),
      ],
      child: router == null
          ? MaterialApp(
              locale: const Locale('ja'),
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              // `showsAccountPage` を渡すと、`ProviderScope` を保ったまま
              // AccountPage だけを外せる（別タブへの移動と同じ状況）。
              home: switch (showsAccountPage) {
                null => const AccountPage(),
                final listenable => ValueListenableBuilder(
                  valueListenable: listenable,
                  builder: (_, shows, _) => shows ? const AccountPage() : const Scaffold(body: Text('別のタブ')),
                ),
              },
            )
          : MaterialApp.router(
              routerConfig: router,
              locale: const Locale('ja'),
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
            ),
    ),
  );

  late SharedPreferences preferences;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    SharedPreferences.setMockInitialValues(const {});
    preferences = await SharedPreferences.getInstance();
  });

  /// サインイン後の画面はスクロールリストなので、テストの小さな画面では
  /// 下部の操作を表示域に入れてからタップする。
  Future<void> tapListItem(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  test('allows Apple sign-in only in the native iOS app', () {
    expect(
      isAppleSignInAvailable(
        isWeb: false,
        platform: TargetPlatform.iOS,
      ),
      isTrue,
    );
    for (final condition in [
      (isWeb: true, platform: TargetPlatform.iOS),
      (isWeb: false, platform: TargetPlatform.android),
      (isWeb: false, platform: TargetPlatform.macOS),
    ]) {
      expect(
        isAppleSignInAvailable(
          isWeb: condition.isWeb,
          platform: condition.platform,
        ),
        isFalse,
      );
    }
  });

  testWidgets('signs in with Google from the signed-out view', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository, preferences: preferences));
    await tester.pumpAndSettle();

    expect(find.text('サインイン'), findsOneWidget);
    expect(find.text('プロフィールや会場イベントの記録は\nアカウントに保存されます'), findsOneWidget);
    expect(find.bySemanticsLabel('Google でサインイン'), findsOneWidget);
    expect(find.text('Appleでサインイン'), findsNothing);
    expect(find.text('メールアドレスでサインイン'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Google でサインイン'));
    await tester.pumpAndSettle();

    expect(repository.calledMethods, ['signInWithGoogle']);
    expect(find.text('Google User'), findsOneWidget);
    expect(find.text('google@example.com'), findsOneWidget);
    expect(find.text('サインイン中'), findsOneWidget);
    expect(find.text('サインイン'), findsNothing);
  });

  for (final flavor in Flavor.values) {
    testWidgets('shows Apple sign-in on ${flavor.shortName} iOS', (tester) async {
      final repository = FakeAuthRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        buildSubject(repository, preferences: preferences, flavor: flavor, showsAppleSignIn: null),
      );
      await tester.pumpAndSettle();

      expect(find.text('Appleでサインイン'), findsOneWidget);

      await tester.tap(find.text('Appleでサインイン'));
      await tester.pumpAndSettle();

      expect(repository.calledMethods, ['signInWithApple']);
      expect(find.text('Apple User'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }

  testWidgets('keeps all sign-in method buttons at the same size', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      buildSubject(repository, preferences: preferences, showsAppleSignIn: true),
    );
    await tester.pumpAndSettle();

    final googleSize = tester.getSize(find.byType(GoogleSignInButton));
    final appleSize = tester.getSize(find.byType(AppleSignInButton));
    final emailSize = tester.getSize(
      find.widgetWithText(OutlinedButton, 'メールアドレスでサインイン'),
    );

    expect(googleSize, const Size(375, 48));
    expect(appleSize, googleSize);
    expect(emailSize, googleSize);
  });

  testWidgets('uses the same typography for every sign-in method', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      buildSubject(repository, preferences: preferences, showsAppleSignIn: true),
    );
    await tester.pumpAndSettle();

    TextStyle effectiveStyle(String label) {
      final finder = find.text(label);
      final text = tester.widget<Text>(finder);
      return DefaultTextStyle.of(tester.element(finder)).style.merge(text.style);
    }

    final styles = [
      effectiveStyle('Google でサインイン'),
      effectiveStyle('Appleでサインイン'),
      effectiveStyle('メールアドレスでサインイン'),
    ];
    for (final style in styles) {
      expect(style.fontSize, 14);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.height, 20 / 14);
    }
  });

  testWidgets('shows a message when sign-in fails', (tester) async {
    final repository = FakeAuthRepository()..nextError = FirebaseAuthException(code: 'network-request-failed');
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      buildSubject(repository, preferences: preferences, showsAppleSignIn: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Appleでサインイン'));
    await tester.pumpAndSettle();

    expect(
      find.text('通信に失敗しました。通信状況を確認してもう一度お試しください'),
      findsOneWidget,
    );
    expect(find.text('Appleでサインイン'), findsOneWidget);
  });

  testWidgets('ignores a sign-in that fails after the card has gone away', (tester) async {
    final repository = FakeAuthRepository()..pendingAction = Completer<void>();
    addTearDown(repository.dispose);
    final showsAccountPage = ValueNotifier(true);
    addTearDown(showsAccountPage.dispose);

    await tester.pumpWidget(
      buildSubject(repository, preferences: preferences, showsAccountPage: showsAccountPage),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Google でサインイン'));
    await tester.pump();
    showsAccountPage.value = false;
    await tester.pump();
    expect(find.byType(SignInCard), findsNothing);

    repository.pendingAction!.completeError(FirebaseAuthException(code: 'network-request-failed'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('stays silent when the user cancels sign-in', (tester) async {
    final repository = FakeAuthRepository()..nextError = FirebaseAuthException(code: 'canceled');
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository, preferences: preferences));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Google でサインイン'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.bySemanticsLabel('Google でサインイン'), findsOneWidget);
  });

  testWidgets(
    'signs out from the signed-in view and clears the cached exchange token and pending share link',
    (tester) async {
      final repository = FakeAuthRepository(
        initialUser: FakeUser(email: 'attendee@example.com'),
      );
      addTearDown(repository.dispose);
      final tokenCache = SharedPreferencesExchangeTokenCacheRepository(preferences);
      await tokenCache.write(
        'fake-uid',
        ExchangeToken(
          value: 'v1.fake-uid.9999999999.deadbeef',
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
      );
      final codeCache = InMemoryExchangeCodeCacheRepository()
        ..write('fake-uid', ExchangeCode(value: '123456', expiresAt: DateTime.now().add(const Duration(minutes: 5))));

      await tester.pumpWidget(
        buildSubject(
          repository,
          preferences: preferences,
          codeCache: codeCache,
          // 未消化のまま置き土産になっている状態を再現する。
          pendingExchangeToken: 'v1.other-uid.9999999999.deadbeef',
          pendingExchangeTokenUid: 'fake-uid',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('attendee@example.com'), findsOneWidget);
      expect(find.text('サインイン中'), findsOneWidget);

      await tapListItem(tester, 'サインアウト');

      expect(repository.calledMethods, ['signOut']);
      expect(find.bySemanticsLabel('Google でサインイン'), findsOneWidget);
      expect(tokenCache.read('fake-uid'), isNull);
      expect(codeCache.read('fake-uid'), isNull);
      expect(
        ProviderScope.containerOf(tester.element(find.byType(AccountPage))).read(pendingExchangeTokenProvider),
        isNull,
      );
    },
  );

  testWidgets(
    'deletes a Google account after confirmation and clears the cached exchange token and pending share link',
    (tester) async {
      final repository = FakeAuthRepository(
        initialUser: FakeUser(
          email: 'attendee@example.com',
          providerIds: const ['google.com'],
        ),
      );
      addTearDown(repository.dispose);
      final tokenCache = SharedPreferencesExchangeTokenCacheRepository(preferences);
      await tokenCache.write(
        'fake-uid',
        ExchangeToken(
          value: 'v1.fake-uid.9999999999.deadbeef',
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
      );
      final codeCache = InMemoryExchangeCodeCacheRepository()
        ..write('fake-uid', ExchangeCode(value: '123456', expiresAt: DateTime.now().add(const Duration(minutes: 5))));

      await tester.pumpWidget(
        buildSubject(
          repository,
          preferences: preferences,
          codeCache: codeCache,
          pendingExchangeToken: 'v1.other-uid.9999999999.deadbeef',
          pendingExchangeTokenUid: 'fake-uid',
        ),
      );
      await tester.pumpAndSettle();

      await tapListItem(tester, 'アカウントを削除');

      expect(find.text('アカウントを削除しますか?'), findsOneWidget);

      await tester.tap(find.text('削除する'));
      await tester.pumpAndSettle();

      expect(repository.calledMethods, ['deleteAccount']);
      expect(repository.lastDeletePassword, isNull);
      expect(repository.beforeDeleteCalled, isTrue);
      expect(find.text('アカウントを削除しました'), findsOneWidget);
      expect(find.bySemanticsLabel('Google でサインイン'), findsOneWidget);
      expect(tokenCache.read('fake-uid'), isNull);
      expect(codeCache.read('fake-uid'), isNull);
      expect(
        ProviderScope.containerOf(tester.element(find.byType(AccountPage))).read(pendingExchangeTokenProvider),
        isNull,
      );
    },
  );

  testWidgets('deletes the profile document together with the account', (tester) async {
    final repository = FakeAuthRepository(
      initialUser: FakeUser(uid: 'uid-1', email: 'attendee@example.com', providerIds: const ['google.com']),
    );
    addTearDown(repository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _profile(id: 'uid-1'));
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(buildSubject(repository, preferences: preferences, profileRepository: profileRepository));
    await tester.pumpAndSettle();

    await tapListItem(tester, 'アカウントを削除');
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(profileRepository.deletedUids, ['uid-1']);
    expect(repository.calledMethods, ['deleteAccount']);
  });

  testWidgets('invites a signed-in user without a profile to create one', (tester) async {
    final repository = FakeAuthRepository(
      initialUser: FakeUser(email: 'attendee@example.com', displayName: 'Attendee'),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository, preferences: preferences));
    await tester.pumpAndSettle();

    expect(find.text('Attendee'), findsOneWidget);
    expect(find.text('プロフィールを登録しましょう'), findsOneWidget);
    expect(find.text('プロフィールを作成'), findsOneWidget);
    expect(find.text('プロフィールを編集'), findsNothing);
  });

  testWidgets('lists the quiz events after signing in on the quiz list, without leaving it', (tester) async {
    final repository = FakeAuthRepository();
    final quizzes = _QuizEventRepository([
      QuizEvent(
        id: 'first',
        title: const LocaleMap(ja: '前半戦', en: 'First round'),
        status: QuizEventStatus.registration,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    ]);
    final router = GoRouter(initialLocation: '/account', routes: app_router.$appRoutes);
    addTearDown(repository.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      buildSubject(repository, preferences: preferences, router: router, quizRepository: quizzes),
    );
    await tester.pumpAndSettle();

    router.go('/account/quiz');
    await tester.pumpAndSettle();

    final quizList = find.byType(QuizEventListPage);
    final signInCard = find.descendant(of: quizList, matching: find.byType(SignInCard));
    expect(signInCard, findsOneWidget);
    expect(quizzes.publishedSubscriptions, 0);

    await tester.tap(find.descendant(of: signInCard, matching: find.byType(GoogleSignInButton)));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/account/quiz');
    expect(signInCard, findsNothing);
    expect(find.descendant(of: quizList, matching: find.text('前半戦')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a check-in link opens the quiz page with its code and offers sign-in there', (tester) async {
    final repository = FakeAuthRepository();
    final router = GoRouter(initialLocation: '/account', routes: app_router.$appRoutes);
    addTearDown(repository.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      buildSubject(repository, preferences: preferences, router: router, quizRepository: _QuizEventRepository()),
    );
    await tester.pumpAndSettle();

    router.go('/account/quiz/event/check-in/654321');
    await tester.pumpAndSettle();

    final page = tester.widget<QuizPage>(find.byType(QuizPage));
    expect((page.eventId, page.checkInCode), ('event', '654321'));
    expect(find.byType(SignInCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (state, user) in [('signed out', null), ('signed in', FakeUser(uid: 'uid-1'))]) {
    testWidgets('opens the venue events hub above the account page while $state', (tester) async {
      final repository = FakeAuthRepository(initialUser: user);
      addTearDown(repository.dispose);
      final router = GoRouter(
        initialLocation: '/account',
        routes: [
          GoRoute(
            path: '/account',
            builder: (_, _) => const AccountPage(),
            routes: [
              GoRoute(
                path: 'venue-events',
                builder: (_, _) => const Scaffold(body: Text('venue events destination')),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(buildSubject(repository, preferences: preferences, router: router));
      await tester.pumpAndSettle();

      await tapListItem(tester, '会場イベントに参加');
      expect(find.text('venue events destination'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(AccountPage), findsOneWidget);
    });
  }

  testWidgets('lines the signed-out venue events entry up with the sign-in card', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(buildSubject(repository, preferences: preferences));
    await tester.pumpAndSettle();

    final tile = find.ancestor(of: find.text('会場イベントに参加'), matching: find.byType(Card));
    expect(find.text('スタンプラリー・プロフィール交換など'), findsOneWidget);
    expect(tester.getSize(tile).width, tester.getSize(find.byType(SignInCard)).width);
    expect(tester.getTopLeft(tile).dy, greaterThan(tester.getBottomLeft(find.byType(SignInCard)).dy));
  });

  testWidgets('shows the saved profile with country, links and bio', (tester) async {
    final repository = FakeAuthRepository(
      initialUser: FakeUser(uid: 'uid-1', email: 'attendee@example.com', displayName: 'Auth Name'),
    );
    addTearDown(repository.dispose);
    final profileRepository = FakeUserProfileRepository(
      initialProfile: _profile(
        id: 'uid-1',
        displayName: 'Profile Name',
        countryOrRegion: 'TW',
        snsLinks: const [SnsLink(type: 'github', value: 'https://github.com/example')],
        bio: 'Flutter が好きです',
      ),
    );
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(buildSubject(repository, preferences: preferences, profileRepository: profileRepository));
    await tester.pumpAndSettle();

    // プロフィールの表示名が Auth の displayName より優先される。
    expect(find.text('Profile Name'), findsOneWidget);
    expect(find.text('Auth Name'), findsNothing);
    expect(find.text('attendee@example.com'), findsOneWidget);
    expect(find.text('台湾'), findsOneWidget);
    expect(find.byType(CountryFlagIcon), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('Flutter が好きです'), findsOneWidget);
    expect(find.text('プロフィールを編集'), findsOneWidget);
    expect(find.text('プロフィールを登録しましょう'), findsNothing);
  });

  testWidgets(
    'completes a pending share-link exchange once signed in with a profile, and shows the result',
    (tester) async {
      final repository = FakeAuthRepository(
        initialUser: FakeUser(uid: 'uid-1', email: 'attendee@example.com'),
      );
      addTearDown(repository.dispose);
      final profileRepository = FakeUserProfileRepository(
        initialProfile: _profile(id: 'uid-1'),
      );
      addTearDown(profileRepository.dispose);
      final exchangeRepository = FakeProfileExchangeRepository();
      addTearDown(exchangeRepository.dispose);
      final expSeconds = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

      await tester.pumpWidget(
        buildSubject(
          repository,
          preferences: preferences,
          profileRepository: profileRepository,
          exchangeRepository: exchangeRepository,
          pendingExchangeToken: 'v1.other-uid.$expSeconds.deadbeef',
        ),
      );
      await tester.pumpAndSettle();

      expect(exchangeRepository.createCalls, [
        (uid: 'uid-1', otherUid: 'other-uid', token: 'v1.other-uid.$expSeconds.deadbeef'),
      ]);
      expect(find.text('プロフィールを交換しました'), findsOneWidget);
    },
  );

  testWidgets(
    'clears the pending share-link token even when the tab is left before the exchange lands',
    (tester) async {
      final repository = FakeAuthRepository(
        initialUser: FakeUser(uid: 'uid-1', email: 'attendee@example.com'),
      );
      addTearDown(repository.dispose);
      final profileRepository = FakeUserProfileRepository(
        initialProfile: _profile(id: 'uid-1'),
      );
      addTearDown(profileRepository.dispose);
      final exchangeRepository = FakeProfileExchangeRepository();
      addTearDown(exchangeRepository.dispose);
      final gate = Completer<void>();
      exchangeRepository.createGate = gate;
      final showsAccountPage = ValueNotifier(true);
      addTearDown(showsAccountPage.dispose);
      final expSeconds = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

      await tester.pumpWidget(
        buildSubject(
          repository,
          preferences: preferences,
          profileRepository: profileRepository,
          exchangeRepository: exchangeRepository,
          pendingExchangeToken: 'v1.other-uid.$expSeconds.deadbeef',
          showsAccountPage: showsAccountPage,
        ),
      );
      await tester.pumpAndSettle();

      expect(exchangeRepository.createCalls, hasLength(1));

      showsAccountPage.value = false;
      await tester.pumpAndSettle();

      gate.complete();
      await tester.pumpAndSettle();

      // 破棄済みの WidgetRef を触って例外になると、交換は成立しているのに
      // 保留トークンが残り、次にこのタブへ戻ったときに再処理される。
      expect(tester.takeException(), isNull);
      expect(
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(pendingExchangeTokenProvider),
        isNull,
      );
    },
  );

  testWidgets('starts a pending share-link exchange only once when the tab is left and reopened mid-flight', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      initialUser: FakeUser(uid: 'uid-1', email: 'attendee@example.com'),
    );
    addTearDown(repository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _profile(id: 'uid-1'));
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository()..createGate = Completer<void>();
    addTearDown(exchangeRepository.dispose);
    final showsAccountPage = ValueNotifier(true);
    addTearDown(showsAccountPage.dispose);
    final expSeconds = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

    await tester.pumpWidget(
      buildSubject(
        repository,
        preferences: preferences,
        profileRepository: profileRepository,
        exchangeRepository: exchangeRepository,
        pendingExchangeToken: 'v1.other-uid.$expSeconds.deadbeef',
        showsAccountPage: showsAccountPage,
      ),
    );
    await tester.pumpAndSettle();
    expect(exchangeRepository.createCalls, hasLength(1));

    showsAccountPage.value = false;
    await tester.pumpAndSettle();
    showsAccountPage.value = true;
    await tester.pumpAndSettle();

    exchangeRepository.createGate!.complete();
    await tester.pumpAndSettle();
    expect(exchangeRepository.createCalls, hasLength(1));
  });

  testWidgets('starts a share-link exchange only once when the visitor leaves the link for this tab mid-flight', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      initialUser: FakeUser(uid: 'uid-1', email: 'attendee@example.com'),
    );
    addTearDown(repository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _profile(id: 'uid-1'));
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository()..createGate = Completer<void>();
    addTearDown(exchangeRepository.dispose);
    final expSeconds = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
    final router = GoRouter(initialLocation: '/x/v1.other-uid.$expSeconds.deadbeef', routes: app_router.$appRoutes);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      buildSubject(
        repository,
        preferences: preferences,
        profileRepository: profileRepository,
        exchangeRepository: exchangeRepository,
        router: router,
      ),
    );
    // 交換を止めている間はリンクの画面のローディングが回り続けるため、
    // `pumpAndSettle` ではなくフレームを進める。
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump();
    }
    expect(exchangeRepository.createCalls, hasLength(1));

    router.go('/account');
    await tester.pumpAndSettle();
    expect(find.byType(AccountPage), findsOneWidget);

    exchangeRepository.createGate!.complete();
    await tester.pumpAndSettle();
    expect(exchangeRepository.createCalls, hasLength(1));
  });

  testWidgets(
    'discards a pending share-link token left behind by a different uid instead of resolving it',
    (tester) async {
      final repository = FakeAuthRepository(
        initialUser: FakeUser(uid: 'uid-1', email: 'attendee@example.com'),
      );
      addTearDown(repository.dispose);
      final profileRepository = FakeUserProfileRepository(
        initialProfile: _profile(id: 'uid-1'),
      );
      addTearDown(profileRepository.dispose);
      final exchangeRepository = FakeProfileExchangeRepository();
      addTearDown(exchangeRepository.dispose);
      final expSeconds = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

      await tester.pumpWidget(
        buildSubject(
          repository,
          preferences: preferences,
          profileRepository: profileRepository,
          exchangeRepository: exchangeRepository,
          // uid-1 のこの端末で、以前サインインしていた別ユーザーが
          // プロフィール未作成のまま残していった置き土産。
          pendingExchangeToken: 'v1.other-uid.$expSeconds.deadbeef',
          pendingExchangeTokenUid: 'a-different-uid',
        ),
      );
      await tester.pumpAndSettle();

      expect(exchangeRepository.createCalls, isEmpty);
      expect(find.text('プロフィールを交換しました'), findsNothing);
      expect(
        ProviderScope.containerOf(tester.element(find.byType(AccountPage))).read(pendingExchangeTokenProvider),
        isNull,
      );
    },
  );

  testWidgets('asks for the current password before deleting an email account', (tester) async {
    final repository = FakeAuthRepository(
      initialUser: FakeUser(
        email: 'attendee@example.com',
        providerIds: const ['password'],
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository, preferences: preferences));
    await tester.pumpAndSettle();

    await tapListItem(tester, 'アカウントを削除');
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(find.text('パスワードの確認'), findsOneWidget);
    expect(repository.calledMethods, isEmpty);

    await tester.enterText(find.byType(TextField), 'password123');
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(repository.calledMethods, ['deleteAccount']);
    expect(repository.lastDeletePassword, 'password123');
    expect(find.bySemanticsLabel('Google でサインイン'), findsOneWidget);
  });

  testWidgets('keeps the account when deletion is canceled', (tester) async {
    final repository = FakeAuthRepository(
      initialUser: FakeUser(
        email: 'attendee@example.com',
        providerIds: const ['google.com'],
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository, preferences: preferences));
    await tester.pumpAndSettle();

    await tapListItem(tester, 'アカウントを削除');
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(repository.calledMethods, isEmpty);
    expect(find.text('attendee@example.com'), findsOneWidget);
  });

  testWidgets('shows the venue events entry instead of a feature list when event_features_enabled is true', (
    tester,
  ) async {
    final repository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      buildSubject(
        repository,
        preferences: preferences,
        remoteConfigRepository: FakeRemoteConfigRepository(
          initialValues: const {RemoteConfigKeys.eventFeaturesEnabled: true},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('会場イベントに参加'), findsOneWidget);
    for (final title in ['ミッション', 'クイズ大会', '応援LT参加', 'プロフィール交換', 'SNS投稿登録', 'スタンプラリー']) {
      expect(find.text(title), findsNothing, reason: title);
    }
  });

  for (final (state, user) in [('signed out', null), ('signed in', FakeUser(uid: 'uid-1'))]) {
    testWidgets('hides the venue events entry while $state when event_features_enabled is false', (tester) async {
      final repository = FakeAuthRepository(initialUser: user);
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        buildSubject(
          repository,
          preferences: preferences,
          remoteConfigRepository: FakeRemoteConfigRepository(
            initialValues: const {RemoteConfigKeys.eventFeaturesEnabled: false},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('会場イベントに参加'), findsNothing);
      expect(find.bySemanticsLabel('Google でサインイン'), user == null ? findsOneWidget : findsNothing);
    });
  }

  testWidgets('keeps the account actions when event_features_enabled is false', (
    tester,
  ) async {
    final repository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      buildSubject(
        repository,
        preferences: preferences,
        remoteConfigRepository: FakeRemoteConfigRepository(
          initialValues: const {RemoteConfigKeys.eventFeaturesEnabled: false},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 削除・サインアウトなどアカウント自体の操作は引き続き表示される。
    expect(find.text('サインアウト'), findsOneWidget);
    expect(find.text('アカウントを削除'), findsOneWidget);
  });

  testWidgets('hides the venue events entry as soon as the flag flips while the tab is open', (tester) async {
    final repository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(repository.dispose);
    final remoteConfig = FakeRemoteConfigRepository(
      initialValues: const {RemoteConfigKeys.eventFeaturesEnabled: true},
    );
    addTearDown(remoteConfig.dispose);

    await tester.pumpWidget(
      buildSubject(repository, preferences: preferences, remoteConfigRepository: remoteConfig),
    );
    await tester.pumpAndSettle();

    expect(find.text('会場イベントに参加'), findsOneWidget);

    remoteConfig.setValue(RemoteConfigKeys.eventFeaturesEnabled, false);
    await tester.pumpAndSettle();

    expect(find.text('会場イベントに参加'), findsNothing);
  });
}

class _QuizEventRepository extends Fake implements QuizEventRepository {
  _QuizEventRepository([this.events = const []]);

  final List<QuizEvent> events;
  int publishedSubscriptions = 0;

  @override
  Stream<List<QuizEvent>> watchPublished() {
    publishedSubscriptions++;
    return Stream.value(events);
  }
}

UserProfile _profile({
  required String id,
  String displayName = 'Attendee',
  String countryOrRegion = 'JP',
  List<SnsLink> snsLinks = const [],
  String? bio,
}) => UserProfile(
  id: id,
  displayName: displayName,
  countryOrRegion: countryOrRegion,
  snsLinks: snsLinks,
  bio: bio,
  createdAt: DateTime.utc(2026, 8),
  updatedAt: DateTime.utc(2026, 8),
);

/// Seeds `pendingExchangeTokenProvider` with [_initial] for a test, instead
/// of the real notifier's `build() => null`.
class _SeededPendingExchangeTokenNotifier extends PendingExchangeTokenNotifier {
  _SeededPendingExchangeTokenNotifier(this._initial);

  final PendingExchangeToken _initial;

  @override
  PendingExchangeToken? build() => _initial;
}
