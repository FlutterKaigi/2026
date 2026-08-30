import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository_provider.dart';
import 'package:app/feature/exchange/ui/page/exchange_link_page.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';
import 'fake_profile_exchange_repository.dart';
import 'fake_user_profile_repository.dart';

void main() {
  const currentUid = 'uid-1';
  const defaultToken = 'v1.uid-2.9999999999.sig';

  Widget buildSubject({
    required FakeAuthRepository authRepository,
    FakeUserProfileRepository? profileRepository,
    FakeProfileExchangeRepository? exchangeRepository,
    String token = defaultToken,
  }) => TranslationProvider(
    child: ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        userProfileRepositoryProvider.overrideWithValue(profileRepository ?? FakeUserProfileRepository()),
        profileExchangeRepositoryProvider.overrideWithValue(exchangeRepository ?? FakeProfileExchangeRepository()),
      ],
      child: MaterialApp(
        locale: const Locale('ja'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ExchangeLinkPage(token: token),
      ),
    ),
  );

  UserProfile profile({String id = currentUid}) => UserProfile(
    id: id,
    displayName: 'Attendee',
    countryOrRegion: 'JP',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  test('builds the typed /x/:token route', () {
    expect(const ExchangeLinkRoute(token: 'v1.uid.999.sig').location, '/x/v1.uid.999.sig');
  });

  testWidgets('prompts to sign in while signed out', (tester) async {
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);

    await tester.pumpWidget(buildSubject(authRepository: authRepository));
    await tester.pumpAndSettle();

    expect(find.text('このリンクからプロフィールを交換するにはサインインしてください'), findsOneWidget);
    expect(find.text('サインインする'), findsOneWidget);
  });

  testWidgets('prompts to create a profile when signed in without one', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: currentUid));
    addTearDown(authRepository.dispose);

    await tester.pumpWidget(buildSubject(authRepository: authRepository));
    await tester.pumpAndSettle();

    expect(find.text('プロフィールを作成しましょう'), findsOneWidget);
    expect(find.text('プロフィールを作成'), findsOneWidget);
  });

  testWidgets('completes the exchange and shows a success message with a way to the list', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: currentUid));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: profile());
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        exchangeRepository: exchangeRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('プロフィールを交換しました'), findsOneWidget);
    expect(find.text('交換した人一覧を見る'), findsOneWidget);
    expect(exchangeRepository.exchangesFor(currentUid).single.id, 'uid-2');
  });

  testWidgets('shows a duplicate message when already exchanged with this attendee', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: currentUid));
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

    expect(find.text('既に交換済みです'), findsOneWidget);
    // Still offers a way to the list — the pair is exchanged either way.
    expect(find.text('交換した人一覧を見る'), findsOneWidget);
  });

  testWidgets('shows a self-scan message without offering the list, and a way home', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: currentUid));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: profile());
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        token: 'v1.$currentUid.9999999999.sig',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('自分のQRコードです'), findsOneWidget);
    expect(find.text('交換した人一覧を見る'), findsNothing);
    expect(find.text('閉じる'), findsOneWidget);
  });

  testWidgets('shows a malformed-link message for a token that does not parse', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: currentUid));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: profile());
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(
      buildSubject(authRepository: authRepository, profileRepository: profileRepository, token: 'not-a-token'),
    );
    await tester.pumpAndSettle();

    expect(find.text('不正なQRコードです'), findsOneWidget);
  });
}
