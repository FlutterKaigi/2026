import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/exchange/ui/page/exchange_share_link_page.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';
import 'fake_profile_exchange_repository.dart';
import 'fake_user_profile_repository.dart';

void main() {
  Widget buildSubject({
    required String token,
    required FakeAuthRepository authRepository,
    required FakeUserProfileRepository profileRepository,
    required FakeProfileExchangeRepository exchangeRepository,
  }) {
    final router = GoRouter(
      initialLocation: '/x/$token',
      routes: [
        GoRoute(
          path: '/x/:token',
          builder: (context, state) => ExchangeShareLinkPage(token: state.pathParameters['token']!),
        ),
        GoRoute(
          path: '/account',
          builder: (_, _) => const Scaffold(body: Text('account destination')),
        ),
        GoRoute(
          path: '/account/exchange/list',
          builder: (_, _) => const Scaffold(body: Text('list destination')),
        ),
        GoRoute(
          path: '/info',
          builder: (_, _) => const Scaffold(body: Text('home destination')),
        ),
      ],
    );

    return TranslationProvider(
      child: ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          userProfileRepositoryProvider.overrideWithValue(profileRepository),
          profileExchangeRepositoryProvider.overrideWithValue(exchangeRepository),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('ja'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ),
    );
  }

  String futureToken(String uid) {
    final expSeconds = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
    return 'v1.$uid.$expSeconds.deadbeef';
  }

  UserProfile ownProfile() => UserProfile(
    id: 'uid-1',
    displayName: 'Me',
    countryOrRegion: 'JP',
    createdAt: DateTime.utc(2026, 8),
    updatedAt: DateTime.utc(2026, 8),
  );

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  testWidgets('rejects a malformed token before requiring sign-in', (tester) async {
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();
    addTearDown(exchangeRepository.dispose);

    await tester.pumpWidget(
      buildSubject(
        token: 'not-a-token',
        authRepository: authRepository,
        profileRepository: FakeUserProfileRepository(),
        exchangeRepository: exchangeRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('このリンクは無効です'), findsOneWidget);
    expect(find.text('サインインする'), findsNothing);
  });

  testWidgets('rejects an already-expired token before requiring sign-in', (tester) async {
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();
    addTearDown(exchangeRepository.dispose);
    final pastSeconds = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

    await tester.pumpWidget(
      buildSubject(
        token: 'v1.other-uid.$pastSeconds.deadbeef',
        authRepository: authRepository,
        profileRepository: FakeUserProfileRepository(),
        exchangeRepository: exchangeRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('このリンクの有効期限が切れています'), findsOneWidget);
  });

  testWidgets('shows the usual sign-in prompt for a well-formed token when signed out', (tester) async {
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();
    addTearDown(exchangeRepository.dispose);

    await tester.pumpWidget(
      buildSubject(
        token: futureToken('other-uid'),
        authRepository: authRepository,
        profileRepository: FakeUserProfileRepository(),
        exchangeRepository: exchangeRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('サインインすると自分のQRコードを表示できます'), findsOneWidget);
    await tester.tap(find.text('サインインする'));
    await tester.pumpAndSettle();

    expect(find.text('account destination'), findsOneWidget);
  });

  testWidgets("shows a dedicated message for the holder's own link", (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();
    addTearDown(exchangeRepository.dispose);

    await tester.pumpWidget(
      buildSubject(
        token: futureToken('uid-1'),
        authRepository: authRepository,
        profileRepository: FakeUserProfileRepository(initialProfile: ownProfile()),
        exchangeRepository: exchangeRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('これは自分の共有リンクです'), findsOneWidget);
    expect(exchangeRepository.createCalls, isEmpty);
  });

  testWidgets('creates the exchange for another attendee and offers to view the list', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();
    addTearDown(exchangeRepository.dispose);
    final token = futureToken('other-uid');

    await tester.pumpWidget(
      buildSubject(
        token: token,
        authRepository: authRepository,
        profileRepository: FakeUserProfileRepository(initialProfile: ownProfile()),
        exchangeRepository: exchangeRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(exchangeRepository.createCalls, [(uid: 'uid-1', otherUid: 'other-uid', token: token)]);
    expect(find.text('プロフィールを交換しました'), findsOneWidget);

    await tester.tap(find.text('交換した人を見る'));
    await tester.pumpAndSettle();

    expect(find.text('list destination'), findsOneWidget);
  });

  testWidgets('reports an already-existing exchange without erroring', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository(
      initialExchangesByUid: {
        'uid-1': [
          ProfileExchange(id: 'other-uid', createdAt: DateTime.utc(2026, 8, 2), origin: ProfileExchangeOrigin.scan),
        ],
      },
    );
    addTearDown(exchangeRepository.dispose);
    exchangeRepository.nextError = const ProfileExchangeAlreadyExistsException();

    await tester.pumpWidget(
      buildSubject(
        token: futureToken('other-uid'),
        authRepository: authRepository,
        profileRepository: FakeUserProfileRepository(initialProfile: ownProfile()),
        exchangeRepository: exchangeRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('すでに交換済みです'), findsOneWidget);
  });
}
