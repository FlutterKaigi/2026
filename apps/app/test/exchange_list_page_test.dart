import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository_provider.dart';
import 'package:app/feature/exchange/ui/page/exchange_list_page.dart';
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
  Widget buildSubject({
    required FakeAuthRepository authRepository,
    required FakeProfileExchangeRepository exchangeRepository,
    FakeUserProfileRepository? profileRepository,
  }) => TranslationProvider(
    child: ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        profileExchangeRepositoryProvider.overrideWithValue(exchangeRepository),
        userProfileRepositoryProvider.overrideWithValue(profileRepository ?? FakeUserProfileRepository()),
      ],
      child: MaterialApp(
        locale: const Locale('ja'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const ExchangeListPage(),
      ),
    ),
  );

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  test('builds the typed exchange routes', () {
    expect(const ExchangeHomeRoute().location, '/account/exchange');
    expect(const ExchangeScanRoute().location, '/account/exchange/scan');
    expect(const ExchangeListRoute().location, '/account/exchange/list');
  });

  testWidgets('shows the empty state with no exchanges', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);

    await tester.pumpWidget(
      buildSubject(authRepository: authRepository, exchangeRepository: FakeProfileExchangeRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('まだ誰とも交換していません'), findsOneWidget);
  });

  testWidgets('lists exchanged profiles joined with their UserProfile', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository(
      initialExchanges: [
        ProfileExchange(id: 'uid-2', createdAt: DateTime.now(), origin: ProfileExchangeOrigin.mirror),
      ],
    );
    final profileRepository = FakeUserProfileRepository(
      initialProfile: UserProfile(
        id: 'uid-2',
        displayName: 'Bob',
        countryOrRegion: 'US',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        exchangeRepository: exchangeRepository,
        profileRepository: profileRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsOneWidget);
    expect(find.textContaining('1 人と交換しました'), findsOneWidget);
  });

  testWidgets('shows a placeholder when the other attendee deleted their profile', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository(
      initialExchanges: [
        ProfileExchange(id: 'uid-2', createdAt: DateTime.now(), origin: ProfileExchangeOrigin.mirror),
      ],
    );

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        exchangeRepository: exchangeRepository,
        profileRepository: FakeUserProfileRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('削除されたプロフィールです'), findsOneWidget);
  });

  testWidgets("deletes an exchange from the signed-in user's own list after confirming", (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository(
      initialExchanges: [
        ProfileExchange(id: 'uid-2', createdAt: DateTime.now(), origin: ProfileExchangeOrigin.mirror),
      ],
    );
    final profileRepository = FakeUserProfileRepository(
      initialProfile: UserProfile(
        id: 'uid-2',
        displayName: 'Bob',
        countryOrRegion: 'US',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        exchangeRepository: exchangeRepository,
        profileRepository: profileRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('一覧から削除しますか?'), findsOneWidget);

    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(exchangeRepository.deletedOtherUids, ['uid-2']);
    expect(find.text('まだ誰とも交換していません'), findsOneWidget);
  });

  testWidgets('keeps the exchange when deletion is canceled', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository(
      initialExchanges: [
        ProfileExchange(id: 'uid-2', createdAt: DateTime.now(), origin: ProfileExchangeOrigin.mirror),
      ],
    );
    final profileRepository = FakeUserProfileRepository(
      initialProfile: UserProfile(
        id: 'uid-2',
        displayName: 'Bob',
        countryOrRegion: 'US',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        exchangeRepository: exchangeRepository,
        profileRepository: profileRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(exchangeRepository.deletedOtherUids, isEmpty);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('opens the detail sheet with SNS links and a note field on tap', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository(
      initialExchanges: [
        ProfileExchange(id: 'uid-2', createdAt: DateTime.now(), origin: ProfileExchangeOrigin.mirror),
      ],
    );
    final profileRepository = FakeUserProfileRepository(
      initialProfile: UserProfile(
        id: 'uid-2',
        displayName: 'Bob',
        countryOrRegion: 'US',
        snsLinks: const [SnsLink(type: 'github', value: 'https://github.com/bob')],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        exchangeRepository: exchangeRepository,
        profileRepository: profileRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('メモ'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Flutter が好きな人');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(exchangeRepository.savedNotes, ['Flutter が好きな人']);
    expect(find.text('メモを保存しました'), findsOneWidget);
  });
}
