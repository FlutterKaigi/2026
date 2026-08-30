import 'package:app/core/designsystem/theme/app_theme.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/exchange/data/exchange_code.dart';
import 'package:app/feature/exchange/data/exchange_code_redeem_handler.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/exchange/ui/page/exchange_home_page.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_profile_exchange_repository.dart';
import 'fake_user_profile_repository.dart';

void main() {
  Widget buildSubject({
    required FakeAuthRepository authRepository,
    required FakeUserProfileRepository profileRepository,
    required ExchangeTokenIssuer tokenIssuer,
    required ExchangeCodeIssuer codeIssuer,
    required GoRouter router,
    required SharedPreferences preferences,
    ExchangeCodeRedeemer? codeRedeemer,
    FakeProfileExchangeRepository? exchangeRepository,
    ThemeData? theme,
  }) => TranslationProvider(
    child: ProviderScope(
      // Riverpod 3 retries a throwing provider automatically; tests assert on
      // the error state itself, so retries are disabled here.
      retry: (retryCount, error) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        userProfileRepositoryProvider.overrideWithValue(profileRepository),
        exchangeTokenIssuerProvider.overrideWithValue(tokenIssuer),
        exchangeCodeIssuerProvider.overrideWithValue(codeIssuer),
        exchangeCodeRedeemerProvider.overrideWithValue(codeRedeemer ?? _StubExchangeCodeRedeemer()),
        profileExchangeRepositoryProvider.overrideWithValue(exchangeRepository ?? FakeProfileExchangeRepository()),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme,
        locale: const Locale('ja'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
  );

  Future<SharedPreferences> emptyPreferences() async {
    SharedPreferences.setMockInitialValues(const {});
    return SharedPreferences.getInstance();
  }

  GoRouter buildRouter() {
    final router = GoRouter(
      initialLocation: '/account/exchange',
      routes: [
        GoRoute(
          path: '/account',
          builder: (_, _) => const Scaffold(body: Text('account destination')),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (_, _) => const Scaffold(body: Text('profile destination')),
            ),
            GoRoute(
              path: 'exchange',
              builder: (_, _) => const ExchangeHomePage(),
              routes: [
                GoRoute(
                  path: 'scan',
                  builder: (_, _) => const Scaffold(body: Text('scan destination')),
                ),
                GoRoute(
                  path: 'list',
                  builder: (_, _) => const Scaffold(body: Text('list destination')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    return router;
  }

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  testWidgets('shows a sign-in prompt when signed out and navigates to the account tab', (tester) async {
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository();
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        tokenIssuer: _StubExchangeTokenIssuer(),
        codeIssuer: _StubExchangeCodeIssuer(),
        router: buildRouter(),
        preferences: await emptyPreferences(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('サインインすると自分のQRコードを表示できます'), findsOneWidget);

    await tester.tap(find.text('サインインする'));
    await tester.pumpAndSettle();

    expect(find.text('account destination'), findsOneWidget);
  });

  testWidgets('shows a profile prompt when signed in without a profile', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository();
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        tokenIssuer: _StubExchangeTokenIssuer(),
        codeIssuer: _StubExchangeCodeIssuer(),
        router: buildRouter(),
        preferences: await emptyPreferences(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('プロフィールを作成すると自分のQRコードを表示できます'), findsOneWidget);

    await tester.tap(find.text('プロフィールを作成する'));
    await tester.pumpAndSettle();

    expect(find.text('profile destination'), findsOneWidget);
  });

  testWidgets('shows the own QR code once signed in with a profile', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _profile(id: 'uid-1'));
    addTearDown(profileRepository.dispose);
    final tokenIssuer = _StubExchangeTokenIssuer();

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        tokenIssuer: tokenIssuer,
        codeIssuer: _StubExchangeCodeIssuer(),
        router: buildRouter(),
        preferences: await emptyPreferences(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tokenIssuer.issueCallCount, 1);
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.text('QRコードを読み取る'), findsOneWidget);
    expect(find.text('交換した人を見る'), findsOneWidget);

    await tester.tap(find.text('QRコードを読み取る'));
    await tester.pumpAndSettle();
    expect(find.text('scan destination'), findsOneWidget);
  });

  testWidgets('keeps the QR code on a light background under a dark theme', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _profile(id: 'uid-1'));
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        tokenIssuer: _StubExchangeTokenIssuer(),
        codeIssuer: _StubExchangeCodeIssuer(),
        router: buildRouter(),
        preferences: await emptyPreferences(),
        theme: darkTheme(),
      ),
    );
    await tester.pumpAndSettle();

    // backgroundColor is set explicitly by _QrCard; the module color and
    // quiet-zone padding below are qr_flutter's own defaults, pinned here so
    // a future default change in the package fails this test instead of
    // silently breaking dark-mode scannability.
    final qrImageView = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qrImageView.backgroundColor, Colors.white);
    expect(qrImageView.eyeStyle.color, Colors.black);
    expect(qrImageView.dataModuleStyle.color, Colors.black);
    expect(qrImageView.padding, const EdgeInsets.all(10));
  });

  testWidgets('ignores a cached token left behind by a different uid on the same device', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-2'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _profile(id: 'uid-2'));
    addTearDown(profileRepository.dispose);
    final tokenIssuer = _StubExchangeTokenIssuer();
    final preferences = await emptyPreferences();
    // uid-1 を名乗る別ユーザーが同じ端末で残していったキャッシュ。
    await SharedPreferencesExchangeTokenCacheRepository(preferences).write(
      'uid-1',
      ExchangeToken(value: 'v1.uid-1.9999999999.deadbeef', expiresAt: DateTime.now().add(const Duration(hours: 24))),
    );

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        tokenIssuer: tokenIssuer,
        codeIssuer: _StubExchangeCodeIssuer(),
        router: buildRouter(),
        preferences: preferences,
      ),
    );
    await tester.pumpAndSettle();

    // uid-1 のキャッシュではなく uid-2 として新規発行される。
    expect(tokenIssuer.issueCallCount, 1);
    expect(find.text('QRコードを読み取る'), findsOneWidget);
  });

  testWidgets('shows an error with retry when issuing a token fails', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _profile(id: 'uid-1'));
    addTearDown(profileRepository.dispose);
    final tokenIssuer = _StubExchangeTokenIssuer()..nextError = Exception('boom');

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        tokenIssuer: tokenIssuer,
        codeIssuer: _StubExchangeCodeIssuer(),
        router: buildRouter(),
        preferences: await emptyPreferences(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('データを読み込めませんでした'), findsOneWidget);

    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();

    expect(find.text('QRコードを読み取る'), findsOneWidget);
    expect(tokenIssuer.issueCallCount, 2);
  });

  testWidgets('shows the own 6-digit code with its expiry', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _profile(id: 'uid-1'));
    addTearDown(profileRepository.dispose);
    final codeIssuer = _StubExchangeCodeIssuer();

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        tokenIssuer: _StubExchangeTokenIssuer(),
        codeIssuer: codeIssuer,
        router: buildRouter(),
        preferences: await emptyPreferences(),
      ),
    );
    await tester.pumpAndSettle();

    expect(codeIssuer.issueCallCount, 1);
    expect(find.text('123 456'), findsOneWidget);
    // The own QR card also shows a "有効期限 ... まで" expiry, so this expects
    // two matches (QR + code) rather than asserting on the exact wording.
    expect(find.textContaining('有効期限'), findsNWidgets(2));
  });

  testWidgets('shows the expired state and reissues the 6-digit code on demand', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _profile(id: 'uid-1'));
    addTearDown(profileRepository.dispose);
    final codeIssuer = _StubExchangeCodeIssuer()..nextExpiresAt = DateTime.now().subtract(const Duration(seconds: 1));

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        tokenIssuer: _StubExchangeTokenIssuer(),
        codeIssuer: codeIssuer,
        router: buildRouter(),
        preferences: await emptyPreferences(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('コードの有効期限が切れました'), findsOneWidget);

    codeIssuer.nextExpiresAt = null;
    await tester.ensureVisible(find.text('コードを再発行'));
    await tester.tap(find.text('コードを再発行'));
    await tester.pumpAndSettle();

    expect(codeIssuer.issueCallCount, 2);
    expect(find.textContaining('有効期限'), findsNWidgets(2));
  });

  testWidgets("redeems another attendee's 6-digit code", (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _profile(id: 'uid-1'));
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();
    addTearDown(exchangeRepository.dispose);
    final codeRedeemer = _StubExchangeCodeRedeemer();

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        tokenIssuer: _StubExchangeTokenIssuer(),
        codeIssuer: _StubExchangeCodeIssuer(),
        codeRedeemer: codeRedeemer,
        exchangeRepository: exchangeRepository,
        router: buildRouter(),
        preferences: await emptyPreferences(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(TextField).last);
    await tester.enterText(find.byType(TextField).last, '654321');
    await tester.ensureVisible(find.text('交換する'));
    await tester.tap(find.text('交換する'));
    await tester.pumpAndSettle();

    expect(exchangeRepository.createCalls, [(uid: 'uid-1', otherUid: 'uid-2', token: 'v1.uid-2.9999999999.deadbeef')]);
    expect(find.text('プロフィールを交換しました'), findsOneWidget);
  });

  testWidgets('shows a message when the entered code is invalid', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _profile(id: 'uid-1'));
    addTearDown(profileRepository.dispose);
    final codeRedeemer = _StubExchangeCodeRedeemer()..nextError = _fakeInvalidCodeException;

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        tokenIssuer: _StubExchangeTokenIssuer(),
        codeIssuer: _StubExchangeCodeIssuer(),
        codeRedeemer: codeRedeemer,
        router: buildRouter(),
        preferences: await emptyPreferences(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(TextField).last);
    await tester.enterText(find.byType(TextField).last, '654321');
    await tester.ensureVisible(find.text('交換する'));
    await tester.tap(find.text('交換する'));
    await tester.pumpAndSettle();

    expect(find.text('コードが見つからないか、有効期限が切れています'), findsOneWidget);
  });
}

class _StubExchangeTokenIssuer implements ExchangeTokenIssuer {
  int issueCallCount = 0;

  /// When set, the next [issue] throws this error once.
  Exception? nextError;

  @override
  Future<ExchangeToken> issue() async {
    issueCallCount++;
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    return ExchangeToken(
      value: 'v1.uid-1.9999999999.deadbeef',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }
}

class _StubExchangeCodeIssuer implements ExchangeCodeIssuer {
  int issueCallCount = 0;

  /// Overrides the next issued code's expiry; defaults to 5 minutes from now.
  DateTime? nextExpiresAt;

  @override
  Future<ExchangeCode> issue() async {
    issueCallCount++;
    return ExchangeCode(
      value: '123456',
      expiresAt: nextExpiresAt ?? DateTime.now().add(const Duration(minutes: 5)),
    );
  }
}

final _fakeInvalidCodeException = FirebaseFunctionsException(code: 'not-found', message: 'not found');

class _StubExchangeCodeRedeemer implements ExchangeCodeRedeemer {
  /// When set, the next [redeem] throws this error once.
  Exception? nextError;

  @override
  Future<ExchangeToken> redeem(String code) async {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    return ExchangeToken(
      value: 'v1.uid-2.9999999999.deadbeef',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }
}

UserProfile _profile({required String id}) => UserProfile(
  id: id,
  displayName: 'Attendee',
  countryOrRegion: 'JP',
  createdAt: DateTime.utc(2026, 8),
  updatedAt: DateTime.utc(2026, 8),
);
