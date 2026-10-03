import 'package:app/core/designsystem/theme/app_theme.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/mission/ui/page/mission_page.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:app/feature/sns_post/data/sns_post_provider.dart';
import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';
import 'fake_profile_exchange_repository.dart';
import 'fake_sns_post_repository.dart';
import 'fake_support_lt_repository.dart';
import 'fake_user_profile_repository.dart';
import 'test_profiles.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeUserProfileRepository profiles;
  late FakeProfileExchangeRepository exchanges;
  late FakeSupportLtRepository lt;
  late FakeSnsPostRepository sns;
  late GoRouter router;

  setUpAll(() async => AppLocale.en.build());
  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    auth = FakeAuthRepository(
      initialUser: FakeUser(uid: 'me', displayName: 'Participant'),
    );
    profiles = FakeUserProfileRepository(initialProfile: profile('me', 'JP'));
    for (final entry in [('a', 'JP'), ('b', 'JP'), ('c', 'US')]) {
      await profiles.save(profile(entry.$1, entry.$2));
    }
    exchanges = FakeProfileExchangeRepository(
      initialExchangesByUid: {
        'me': [
          for (final uid in ['a', 'b', 'c'])
            ProfileExchange(id: uid, createdAt: DateTime.utc(2026), origin: ProfileExchangeOrigin.scan),
        ],
      },
    );
    lt = FakeSupportLtRepository();
    sns = FakeSnsPostRepository();
    router = GoRouter(
      initialLocation: '/account/missions',
      routes: [
        GoRoute(path: '/account/missions', builder: (_, _) => const MissionPage()),
        for (final path in ['support-lt', 'exchange', 'sns-post', 'profile'])
          GoRoute(
            path: '/account/$path',
            builder: (_, _) => Scaffold(body: Text('$path destination')),
          ),
      ],
    );
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);
    addTearDown(exchanges.dispose);
    addTearDown(lt.dispose);
    addTearDown(sns.dispose);
    addTearDown(router.dispose);
  });

  Widget subject({AppLocale locale = AppLocale.ja, bool dark = false}) => TranslationProvider(
    child: ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        userProfileRepositoryProvider.overrideWithValue(profiles),
        profileExchangeRepositoryProvider.overrideWithValue(exchanges),
        supportLtRepositoryProvider.overrideWithValue(lt),
        snsPostRepositoryProvider.overrideWithValue(sns),
        appleSignInAvailabilityProvider.overrideWithValue(false),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: dark ? darkTheme() : lightTheme(),
        locale: locale.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
  );

  void registerLt() =>
      lt.setRegistration(SupportLtRegistration(uid: 'me', displayName: 'me', registeredAt: DateTime.utc(2026)));
  Future<void> registerSns() =>
      sns.save(uid: 'me', url: 'https://x.com/test/status/123', companion: SnsPostCompanion.staff);

  testWidgets('shows individual missions and moves to all complete with live updates', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('3 / 3人と交換'), findsOneWidget);
    expect(find.text('未達成'), findsNWidgets(2));
    registerLt();
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await registerSns();
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('すべて達成！'), findsOneWidget);
    expect(find.text('達成'), findsNWidgets(3));
  });

  testWidgets('country changes and deleted exchanges recalculate both conditions', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await profiles.save(profile('c', 'JP'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.text('3 / 3人と交換'), findsOneWidget);
    await profiles.save(profile('me', 'US'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    await exchanges.delete(uid: 'me', otherUid: 'b');
    await tester.pumpAndSettle();
    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.text('2 / 3人と交換'), findsOneWidget);
  });

  testWidgets('unverified scans and missing profiles never earn a stamp', (tester) async {
    await exchanges.delete(uid: 'me', otherUid: 'c');
    await exchanges.create(uid: 'me', otherUid: 'c', token: 'not-verified');
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(find.text('2 / 3人と交換'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    await profiles.delete('a');
    await tester.pumpAndSettle();
    expect(find.text('1 / 3人と交換'), findsOneWidget);
    await profiles.delete('me');
    await tester.pumpAndSettle();
    expect(find.text('プロフィールで出身国・地域を登録する'), findsOneWidget);
  });

  testWidgets('shows independent load errors and offers a retry', (tester) async {
    sns.watchError = Exception('unavailable');
    registerLt();
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('確認できない項目があります'), findsOneWidget);
    expect(find.text('すべて達成！'), findsNothing);
    sns.watchError = null;
    await registerSns();
    await tester.ensureVisible(find.text('再試行'));
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.text('すべて達成！'), findsOneWidget);
  });

  testWidgets('account switches never retain another attendee completion', (tester) async {
    registerLt();
    await registerSns();
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(find.text('すべて達成！'), findsOneWidget);
    await auth.signInWithGoogle();
    await tester.pumpAndSettle();
    expect(find.text('すべて達成！'), findsNothing);
    expect(find.text('0 / 3'), findsOneWidget);
  });

  testWidgets('a failed profile batch can be retried with the current exchange IDs', (tester) async {
    profiles.watchManyError = Exception('unavailable');
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(find.text('確認できない項目があります'), findsOneWidget);
    expect(profiles.watchedGroups.single, {'a', 'b', 'c'});

    profiles.watchManyError = null;
    await tester.ensureVisible(find.text('再試行'));
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('3 / 3人と交換'), findsOneWidget);
    expect(profiles.watchedGroups.last, {'a', 'b', 'c'});
  });

  testWidgets('signed out visitors do not read private mission data', (tester) async {
    await auth.signOut();
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(find.text('サインインが必要です'), findsOneWidget);
    expect(sns.watchedUids, isEmpty);
    expect(lt.watchedUids, isEmpty);
  });

  for (final entry in [('mission-lt', 'support-lt'), ('mission-exchange', 'exchange'), ('mission-sns', 'sns-post')]) {
    testWidgets('${entry.$1} opens its registration flow', (tester) async {
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(ValueKey(entry.$1)));
      await tester.tap(find.byKey(ValueKey(entry.$1)));
      await tester.pumpAndSettle();
      expect(find.text('${entry.$2} destination'), findsOneWidget);
    });
  }

  testWidgets('English dark mode fits a narrow viewport with larger text', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await tester.binding.setSurfaceSize(const Size(360, 740));
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    registerLt();
    await registerSns();
    await tester.pumpWidget(subject(locale: AppLocale.en, dark: true));
    await tester.pumpAndSettle();
    expect(find.text('All missions complete!'), findsOneWidget);
  });
}
