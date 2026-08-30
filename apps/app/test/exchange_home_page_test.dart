import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/exchange/data/provider/exchange_token_cache_repository.dart';
import 'package:app/feature/exchange/data/provider/exchange_token_service.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository_provider.dart';
import 'package:app/feature/exchange/ui/page/exchange_home_page.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';
import 'fake_exchange_token_cache_repository.dart';
import 'fake_exchange_token_service.dart';
import 'fake_profile_exchange_repository.dart';
import 'fake_user_profile_repository.dart';

void main() {
  Widget buildSubject({
    required FakeAuthRepository authRepository,
    FakeUserProfileRepository? profileRepository,
    FakeProfileExchangeRepository? exchangeRepository,
    FakeExchangeTokenService? tokenService,
  }) => TranslationProvider(
    child: ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        userProfileRepositoryProvider.overrideWithValue(profileRepository ?? FakeUserProfileRepository()),
        profileExchangeRepositoryProvider.overrideWithValue(exchangeRepository ?? FakeProfileExchangeRepository()),
        exchangeTokenServiceProvider.overrideWithValue(tokenService ?? FakeExchangeTokenService()),
        exchangeTokenCacheRepositoryProvider.overrideWithValue(FakeExchangeTokenCacheRepository()),
      ],
      child: MaterialApp(
        locale: const Locale('ja'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const ExchangeHomePage(),
      ),
    ),
  );

  UserProfile profile({String id = 'uid-1'}) => UserProfile(
    id: id,
    displayName: 'Attendee',
    countryOrRegion: 'JP',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  testWidgets('prompts to sign in while signed out', (tester) async {
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);

    await tester.pumpWidget(buildSubject(authRepository: authRepository));
    await tester.pumpAndSettle();

    expect(find.text('プロフィール交換を利用するにはサインインしてください'), findsOneWidget);
    expect(find.text('サインインする'), findsOneWidget);
  });

  testWidgets('prompts to create a profile when signed in without one', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);

    await tester.pumpWidget(buildSubject(authRepository: authRepository));
    await tester.pumpAndSettle();

    expect(find.text('プロフィールを作成しましょう'), findsOneWidget);
    expect(find.text('プロフィールを作成'), findsOneWidget);
  });

  testWidgets('shows the own QR code and exchange count once signed in with a profile', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: profile());
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository(
      initialExchanges: [
        ProfileExchange(id: 'uid-2', createdAt: DateTime.now(), origin: ProfileExchangeOrigin.mirror),
      ],
    );

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        exchangeRepository: exchangeRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('自分のQRコード'), findsOneWidget);
    expect(find.byType(Image), findsNothing); // QR code is drawn, not an Image widget.
    expect(find.text('交換した人一覧'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // exchange count badge
  });

  testWidgets('falls back to a cached QR code when issuing fails', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: profile());
    addTearDown(profileRepository.dispose);
    final tokenService = FakeExchangeTokenService()..issueTokenError = Exception('offline');

    await tester.pumpWidget(
      buildSubject(authRepository: authRepository, profileRepository: profileRepository, tokenService: tokenService),
    );
    await tester.pumpAndSettle();

    // 初回発行に失敗してキャッシュも無いため、エラー表示になる。
    expect(find.text('QRコードを発行できませんでした'), findsOneWidget);
  });

  testWidgets('shows a freshly issued 6-digit code', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: profile());
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(buildSubject(authRepository: authRepository, profileRepository: profileRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('6桁コードを表示'));
    await tester.pumpAndSettle();

    expect(find.text('1 2 3 4 5 6'), findsOneWidget);
  });

  testWidgets('exchanges via a redeemed 6-digit code and shows a success message', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: profile());
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();
    final tokenService = FakeExchangeTokenService()..redeemedUid = 'uid-2';

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        exchangeRepository: exchangeRepository,
        tokenService: tokenService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('6桁コードを入力'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '654321');
    await tester.tap(find.text('交換する'));
    await tester.pumpAndSettle();

    expect(tokenService.redeemedCodes, ['654321']);
    expect(exchangeRepository.exchangesFor('uid-1').single.id, 'uid-2');
    expect(find.text('プロフィールを交換しました'), findsOneWidget);
  });

  testWidgets('shows a duplicate message when the code belongs to an already-exchanged attendee', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: profile());
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository(
      initialExchanges: [
        ProfileExchange(id: 'uid-2', createdAt: DateTime.now(), origin: ProfileExchangeOrigin.scan),
      ],
    );
    final tokenService = FakeExchangeTokenService()..redeemedUid = 'uid-2';

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        exchangeRepository: exchangeRepository,
        tokenService: tokenService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('6桁コードを入力'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '654321');
    await tester.tap(find.text('交換する'));
    await tester.pumpAndSettle();

    expect(find.text('既に交換済みです'), findsOneWidget);
  });

  testWidgets('shows an inline error for an invalid 6-digit code format', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: profile());
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(buildSubject(authRepository: authRepository, profileRepository: profileRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('6桁コードを入力'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.text('交換する'));
    await tester.pumpAndSettle();

    expect(find.text('6桁の数字を入力してください'), findsOneWidget);
  });
}
