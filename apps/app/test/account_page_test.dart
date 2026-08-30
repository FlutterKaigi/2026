import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/environment.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/page/account_page.dart';
import 'package:app/feature/auth/ui/widget/apple_sign_in_button.dart';
import 'package:app/feature/auth/ui/widget/google_sign_in_button.dart';
import 'package:app/feature/exchange/data/exchange_code.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:app/feature/profile/ui/widget/country_flag_widget.dart';
import 'package:data/data.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_user_profile_repository.dart';

void main() {
  Widget buildSubject(
    FakeAuthRepository repository, {
    required SharedPreferences preferences,
    FakeUserProfileRepository? profileRepository,
    ExchangeCodeCacheRepository? codeCache,
    Flavor flavor = Flavor.production,
    bool showsAppleSignIn = false,
  }) => TranslationProvider(
    child: ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        userProfileRepositoryProvider.overrideWithValue(profileRepository ?? FakeUserProfileRepository()),
        appleSignInAvailabilityProvider.overrideWithValue(
          showsAppleSignIn,
        ),
        sharedPreferencesProvider.overrideWithValue(preferences),
        if (codeCache != null) exchangeCodeCacheRepositoryProvider.overrideWithValue(codeCache),
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
      child: MaterialApp(
        locale: const Locale('ja'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const AccountPage(),
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

  test('allows Apple sign-in only on production iOS', () {
    expect(
      isAppleSignInAvailable(
        flavor: Flavor.production,
        isWeb: false,
        platform: TargetPlatform.iOS,
      ),
      isTrue,
    );
    for (final condition in [
      (flavor: Flavor.staging, isWeb: false, platform: TargetPlatform.iOS),
      (flavor: Flavor.develop, isWeb: false, platform: TargetPlatform.iOS),
      (flavor: Flavor.production, isWeb: true, platform: TargetPlatform.iOS),
      (flavor: Flavor.production, isWeb: false, platform: TargetPlatform.android),
      (flavor: Flavor.production, isWeb: false, platform: TargetPlatform.macOS),
    ]) {
      expect(
        isAppleSignInAvailable(
          flavor: condition.flavor,
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

    expect(find.text('サインインが必要です'), findsOneWidget);
    expect(find.bySemanticsLabel('Google でサインイン'), findsOneWidget);
    expect(find.text('Appleでサインイン'), findsNothing);
    expect(find.text('メールアドレスでサインイン'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Google でサインイン'));
    await tester.pumpAndSettle();

    expect(repository.calledMethods, ['signInWithGoogle']);
    expect(find.text('Google User'), findsOneWidget);
    expect(find.text('google@example.com'), findsOneWidget);
    expect(find.text('サインイン中'), findsOneWidget);
    expect(find.text('サインインが必要です'), findsNothing);
  });

  testWidgets('shows Apple sign-in on production iOS', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      buildSubject(repository, preferences: preferences, showsAppleSignIn: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appleでサインイン'), findsOneWidget);

    await tester.tap(find.text('Appleでサインイン'));
    await tester.pumpAndSettle();

    expect(repository.calledMethods, ['signInWithApple']);
    expect(find.text('Apple User'), findsOneWidget);
  });

  testWidgets('hides Apple sign-in on staging iOS', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      buildSubject(repository, preferences: preferences, flavor: Flavor.staging),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appleでサインイン'), findsNothing);
  });

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

  testWidgets('signs out from the signed-in view and clears the cached exchange token', (tester) async {
    final repository = FakeAuthRepository(
      initialUser: FakeUser(email: 'attendee@example.com'),
    );
    addTearDown(repository.dispose);
    final tokenCache = SharedPreferencesExchangeTokenCacheRepository(preferences);
    await tokenCache.write(
      'fake-uid',
      ExchangeToken(value: 'v1.fake-uid.9999999999.deadbeef', expiresAt: DateTime.now().add(const Duration(hours: 24))),
    );
    final codeCache = InMemoryExchangeCodeCacheRepository()
      ..write('fake-uid', ExchangeCode(value: '123456', expiresAt: DateTime.now().add(const Duration(minutes: 5))));

    await tester.pumpWidget(buildSubject(repository, preferences: preferences, codeCache: codeCache));
    await tester.pumpAndSettle();

    expect(find.text('attendee@example.com'), findsOneWidget);
    expect(find.text('サインイン中'), findsOneWidget);

    await tapListItem(tester, 'サインアウト');

    expect(repository.calledMethods, ['signOut']);
    expect(find.bySemanticsLabel('Google でサインイン'), findsOneWidget);
    expect(tokenCache.read('fake-uid'), isNull);
    expect(codeCache.read('fake-uid'), isNull);
  });

  testWidgets('deletes a Google account after confirmation and clears the cached exchange token', (tester) async {
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
      ExchangeToken(value: 'v1.fake-uid.9999999999.deadbeef', expiresAt: DateTime.now().add(const Duration(hours: 24))),
    );
    final codeCache = InMemoryExchangeCodeCacheRepository()
      ..write('fake-uid', ExchangeCode(value: '123456', expiresAt: DateTime.now().add(const Duration(minutes: 5))));

    await tester.pumpWidget(buildSubject(repository, preferences: preferences, codeCache: codeCache));
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
  });

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
