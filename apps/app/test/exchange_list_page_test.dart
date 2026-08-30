import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
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
    required FakeUserProfileRepository profileRepository,
  }) => TranslationProvider(
    child: ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        profileExchangeRepositoryProvider.overrideWithValue(exchangeRepository),
        userProfileRepositoryProvider.overrideWithValue(profileRepository),
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

  testWidgets('shows the empty state when the user has no exchanges', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();
    addTearDown(exchangeRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _ownProfile());
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        exchangeRepository: exchangeRepository,
        profileRepository: profileRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('まだ誰とも交換していません'), findsOneWidget);
  });

  testWidgets('lists exchanged profiles joined from users/{otherUid}', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository(
      initialExchangesByUid: {
        'uid-1': [
          ProfileExchange(
            id: 'uid-2',
            createdAt: DateTime.utc(2026, 8, 2),
            origin: ProfileExchangeOrigin.scan,
          ),
        ],
      },
    );
    addTearDown(exchangeRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _ownProfile());
    addTearDown(profileRepository.dispose);
    await profileRepository.save(
      UserProfile(
        id: 'uid-2',
        displayName: 'Exchanged Attendee',
        countryOrRegion: 'TW',
        snsLinks: const [SnsLink(type: 'github', value: 'https://github.com/example')],
        bio: 'Flutter が好きです',
        createdAt: DateTime.utc(2026, 8),
        updatedAt: DateTime.utc(2026, 8),
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

    expect(find.text('Exchanged Attendee'), findsOneWidget);
    expect(find.text('台湾'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('Flutter が好きです'), findsOneWidget);
    expect(find.text('まだ誰とも交換していません'), findsNothing);
  });

  testWidgets('shows a fallback when the exchanged profile can no longer be read', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository(
      initialExchangesByUid: {
        'uid-1': [
          ProfileExchange(id: 'uid-2', createdAt: DateTime.utc(2026, 8, 2), origin: ProfileExchangeOrigin.mirror),
        ],
      },
    );
    addTearDown(exchangeRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: _ownProfile());
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(
      buildSubject(
        authRepository: authRepository,
        exchangeRepository: exchangeRepository,
        profileRepository: profileRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('このプロフィールは表示できません'), findsOneWidget);
  });
}

/// The signed-in user's own profile, needed only to pass ExchangeAccessGate;
/// unrelated to the exchanged profile under test in each case.
UserProfile _ownProfile() => UserProfile(
  id: 'uid-1',
  displayName: 'Me',
  countryOrRegion: 'JP',
  createdAt: DateTime.utc(2026, 8),
  updatedAt: DateTime.utc(2026, 8),
);
