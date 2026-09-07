import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:app/feature/profile/ui/page/profile_edit_page.dart';
import 'package:app/feature/profile/ui/widget/country_picker_sheet.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';
import 'fake_user_profile_repository.dart';

void main() {
  Widget buildSubject(
    FakeAuthRepository authRepository,
    FakeUserProfileRepository profileRepository,
    GoRouter router,
  ) => TranslationProvider(
    child: ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        userProfileRepositoryProvider.overrideWithValue(profileRepository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('ja'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
  );

  GoRouter buildRouter() {
    final router = GoRouter(
      initialLocation: '/account/profile',
      routes: [
        GoRoute(
          path: '/account',
          builder: (_, _) => const Scaffold(body: Text('account destination')),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (_, _) => const ProfileEditPage(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    return router;
  }

  UserProfile existingProfile() => UserProfile(
    id: 'uid-1',
    displayName: 'Saved Name',
    avatarUrl: 'https://example.com/saved.png',
    countryOrRegion: 'US',
    snsLinks: const [SnsLink(type: 'x', value: 'https://x.com/saved')],
    bio: 'Saved bio',
    createdAt: DateTime.utc(2026, 7),
    updatedAt: DateTime.utc(2026, 7, 2),
  );

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  test('filterCountries matches Japanese name, English name or ISO code', () {
    expect(filterCountries('').length, countries.length);
    expect(filterCountries('台湾').map((c) => c.code), ['TW']);
    expect(filterCountries('germany').map((c) => c.code), ['DE']);
    // ISO コード一致 (KR) に加えて、英語名に "kr" を含む Ukraine も残る。
    expect(filterCountries(' kr ').map((c) => c.code), ['KR', 'UA']);
    expect(filterCountries('zzzz'), isEmpty);
  });

  testWidgets('prefills the display name and avatar from the auth user when creating', (tester) async {
    final authRepository = FakeAuthRepository(
      initialUser: FakeUser(uid: 'uid-1', displayName: 'Auth Name', photoURL: 'https://example.com/auth.png'),
    );
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository();
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(buildSubject(authRepository, profileRepository, buildRouter()));
    await tester.pumpAndSettle();

    expect(find.text('プロフィールを作成'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Auth Name'), findsOneWidget);
    expect(find.text('選択してください'), findsOneWidget);
  });

  testWidgets('requires a country before saving', (tester) async {
    final authRepository = FakeAuthRepository(
      initialUser: FakeUser(uid: 'uid-1', displayName: 'Auth Name'),
    );
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository();
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(buildSubject(authRepository, profileRepository, buildRouter()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, '保存'));
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('出身国・地域を選択してください'), findsOneWidget);
    expect(profileRepository.savedProfiles, isEmpty);
  });

  testWidgets('creates a profile with the picked country and returns to the account tab', (tester) async {
    final authRepository = FakeAuthRepository(
      initialUser: FakeUser(uid: 'uid-1', displayName: 'Auth Name', photoURL: 'https://example.com/auth.png'),
    );
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository();
    addTearDown(profileRepository.dispose);
    final router = buildRouter();

    await tester.pumpWidget(buildSubject(authRepository, profileRepository, router));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Auth Name'), ' Yuhei ');

    // 出身国・地域のピッカーを開いて検索し、選ぶ。
    await tester.tap(find.text('選択してください'));
    await tester.pumpAndSettle();
    expect(find.text('アジア'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '国名・地域名で検索'), 'taiwan');
    await tester.pumpAndSettle();
    expect(find.text('日本'), findsNothing);
    await tester.tap(find.text('台湾'));
    await tester.pumpAndSettle();
    expect(find.text('台湾'), findsOneWidget);
    expect(find.text('選択してください'), findsNothing);

    await tester.enterText(find.widgetWithText(TextFormField, '自己紹介'), 'Hello ');

    await tester.ensureVisible(find.widgetWithText(FilledButton, '保存'));
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(profileRepository.savedProfiles, hasLength(1));
    final saved = profileRepository.savedProfiles.single;
    expect(saved.id, 'uid-1');
    expect(saved.displayName, 'Yuhei');
    expect(saved.avatarUrl, 'https://example.com/auth.png');
    expect(saved.countryOrRegion, 'TW');
    expect(saved.snsLinks, isEmpty);
    expect(saved.bio, 'Hello');
    expect(find.text('プロフィールを保存しました'), findsOneWidget);
    expect(find.text('account destination'), findsOneWidget);
  });

  testWidgets('edits an existing profile and keeps its createdAt', (tester) async {
    final authRepository = FakeAuthRepository(
      initialUser: FakeUser(uid: 'uid-1', displayName: 'Auth Name'),
    );
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: existingProfile());
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(buildSubject(authRepository, profileRepository, buildRouter()));
    await tester.pumpAndSettle();

    expect(find.text('プロフィールを編集'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Saved Name'), findsOneWidget);
    expect(find.text('アメリカ合衆国'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'https://x.com/saved'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Saved bio'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Saved Name'), 'Renamed');
    await tester.ensureVisible(find.widgetWithText(FilledButton, '保存'));
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final saved = profileRepository.savedProfiles.single;
    expect(saved.displayName, 'Renamed');
    expect(saved.countryOrRegion, 'US');
    expect(saved.avatarUrl, 'https://example.com/saved.png');
    expect(saved.snsLinks, const [SnsLink(type: 'x', value: 'https://x.com/saved')]);
    expect(saved.createdAt, DateTime.utc(2026, 7));
  });

  testWidgets('rejects SNS links that are not https URLs', (tester) async {
    final authRepository = FakeAuthRepository(
      initialUser: FakeUser(uid: 'uid-1', displayName: 'Auth Name'),
    );
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: existingProfile());
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(buildSubject(authRepository, profileRepository, buildRouter()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'https://x.com/saved'), 'x.com/saved');
    await tester.ensureVisible(find.widgetWithText(FilledButton, '保存'));
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('https:// から始まる URL を入力してください'), findsOneWidget);
    expect(profileRepository.savedProfiles, isEmpty);
  });

  testWidgets('adds and removes SNS link rows', (tester) async {
    final authRepository = FakeAuthRepository(
      initialUser: FakeUser(uid: 'uid-1', displayName: 'Auth Name'),
    );
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: existingProfile());
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(buildSubject(authRepository, profileRepository, buildRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SNSリンクを追加'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('このリンクを削除'), findsNWidgets(2));

    await tester.enterText(find.widgetWithText(TextFormField, 'URL').last, 'https://github.com/example');
    await tester.pump();
    await tester.ensureVisible(find.byTooltip('このリンクを削除').first);
    await tester.tap(find.byTooltip('このリンクを削除').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('このリンクを削除'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, '保存'));
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    // 先頭行を消したので、残るのは追加した GitHub の行だけ（既定のサービスは X）。
    final saved = profileRepository.savedProfiles.single;
    expect(saved.snsLinks, const [SnsLink(type: 'x', value: 'https://github.com/example')]);
  });

  testWidgets('shows an error and stays on the page when saving fails', (tester) async {
    final authRepository = FakeAuthRepository(
      initialUser: FakeUser(uid: 'uid-1', displayName: 'Auth Name'),
    );
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: existingProfile())
      ..nextError = Exception('offline');
    addTearDown(profileRepository.dispose);

    await tester.pumpWidget(buildSubject(authRepository, profileRepository, buildRouter()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, '保存'));
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('プロフィールを保存できませんでした'), findsOneWidget);
    expect(find.text('account destination'), findsNothing);
  });
}
