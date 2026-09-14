import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/sns_post/data/sns_post_provider.dart';
import 'package:app/feature/sns_post/ui/page/sns_post_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';
import 'fake_sns_post_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeSnsPostRepository repository;
  late GoRouter router;

  setUpAll(() async => AppLocale.en.build());
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    auth = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    repository = FakeSnsPostRepository();
    router = GoRouter(
      initialLocation: '/account/sns-post',
      routes: [
        GoRoute(path: '/account/sns-post', builder: (_, _) => const SnsPostPage()),
        GoRoute(
          path: '/account/missions',
          builder: (_, _) => const Scaffold(body: Text('mission destination')),
        ),
      ],
    );
    addTearDown(auth.dispose);
    addTearDown(repository.dispose);
    addTearDown(router.dispose);
  });

  Widget subject({AppLocale locale = AppLocale.ja}) => TranslationProvider(
    child: ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        snsPostRepositoryProvider.overrideWithValue(repository),
        appleSignInAvailabilityProvider.overrideWithValue(false),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
  );

  Future<void> tapSave(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
  }

  testWidgets('requires sign-in before reading or writing posts', (tester) async {
    await auth.signOut();
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(find.text('サインインが必要です'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(repository.watchedUids, isEmpty);
  });

  testWidgets('requires a category and a valid URL before awarding a stamp', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tapSave(tester);
    expect(find.text('相手のタグを1つ選んでください'), findsOneWidget);
    expect(find.text('有効な投稿URL（https://…）を入力してください'), findsOneWidget);
    await tester.ensureVisible(find.text('スタッフ'));
    await tester.tap(find.text('スタッフ'));
    await tester.enterText(find.byType(TextFormField), 'javascript:alert(1)');
    await tapSave(tester);
    expect(repository.saves, isEmpty);
    expect(find.text('SNS投稿を登録しました'), findsNothing);
  });

  testWidgets('saves the URL and exactly one selected tag then opens missions', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('スタッフ'));
    await tester.tap(find.text('スピーカー'));
    await tester.pump();
    expect(tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).where((chip) => chip.selected), hasLength(1));
    await tester.enterText(find.byType(TextFormField), ' https://x.com/test/status/123 ');
    await tapSave(tester);
    expect(repository.saves.single, (
      uid: 'uid-1',
      url: 'https://x.com/test/status/123',
      companion: SnsPostCompanion.speaker,
    ));
    expect(find.text('SNS投稿を登録しました'), findsOneWidget);
    expect(find.text('https://x.com/test/status/123'), findsOneWidget);
    await tapSave(tester);
    expect(find.text('mission destination'), findsOneWidget);
  });

  testWidgets('restores and edits an existing registration', (tester) async {
    await repository.save(uid: 'uid-1', url: 'https://x.com/test/status/123', companion: SnsPostCompanion.staff);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(find.text('SNS投稿を登録しました'), findsOneWidget);
    await tester.ensureVisible(find.text('URL・タグを修正する'));
    await tester.tap(find.text('URL・タグを修正する'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(find.byType(TextFormField)).controller?.text, 'https://x.com/test/status/123');
    await tester.tap(find.text('初参加の人'));
    await tester.enterText(find.byType(TextFormField), 'https://www.instagram.com/p/new/');
    await tapSave(tester);
    expect(repository.registrations, hasLength(1));
    expect(repository.registrations['uid-1']?.companion, SnsPostCompanion.firstTime);
    expect(find.text('https://www.instagram.com/p/new/'), findsOneWidget);
  });

  testWidgets('disables duplicate submits and retains the form on failed saves', (tester) async {
    repository.saveGate = Completer<void>();
    repository.saveError = Exception('offline');
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('スポンサー'));
    await tester.enterText(find.byType(TextFormField), 'https://x.com/test/status/123');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(tester.widget<TextFormField>(find.byType(TextFormField)).enabled, isFalse);
    expect(repository.saves, hasLength(1));
    repository.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('保存できませんでした。通信状態を確認して、もう一度お試しください。'), findsOneWidget);
    expect(find.text('SNS投稿を登録しました'), findsNothing);
    expect(tester.widget<TextFormField>(find.byType(TextFormField)).controller?.text, 'https://x.com/test/status/123');
    repository.saveError = null;
    await tapSave(tester);
    expect(find.text('SNS投稿を登録しました'), findsOneWidget);
  });

  testWidgets('read errors offer retry rather than an empty registration form', (tester) async {
    repository.watchError = Exception('unavailable');
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('再試行'), findsOneWidget);
    repository.watchError = null;
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('switching accounts discards the previous account draft', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('スタッフ'));
    await tester.enterText(find.byType(TextFormField), 'https://x.com/private/status/123');
    await auth.signInWithGoogle();
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(find.byType(TextFormField)).controller?.text, isEmpty);
    expect(tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).where((chip) => chip.selected), isEmpty);
  });

  testWidgets('English form fits a narrow viewport with larger text', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await tester.binding.setSurfaceSize(const Size(360, 740));
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(subject(locale: AppLocale.en));
    await tester.pumpAndSettle();
    expect(find.text('Register SNS post'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });
}
