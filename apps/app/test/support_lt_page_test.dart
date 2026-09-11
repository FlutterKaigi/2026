import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
import 'package:app/feature/support_lt/ui/page/support_lt_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';
import 'fake_support_lt_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeSupportLtRepository repository;
  late GoRouter router;

  setUpAll(() async => AppLocale.en.build());

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    auth = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    repository = FakeSupportLtRepository();
    router = GoRouter(
      initialLocation: '/account/support-lt',
      routes: [
        GoRoute(
          path: '/account',
          builder: (_, _) => const Scaffold(body: Text('account destination')),
          routes: [
            GoRoute(path: 'support-lt', builder: (_, _) => const SupportLtPage()),
          ],
        ),
      ],
    );
    addTearDown(auth.dispose);
    addTearDown(repository.dispose);
    addTearDown(router.dispose);
  });

  Widget buildSubject({AppLocale locale = AppLocale.ja}) => TranslationProvider(
    child: ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        supportLtRepositoryProvider.overrideWithValue(repository),
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

  Future<void> submit(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextFormField), code);
    await tester.tap(find.widgetWithText(FilledButton, '参加登録する'));
    await tester.pumpAndSettle();
  }

  testWidgets('signed-out visitors sign in on the page without reading registrations first', (tester) async {
    await auth.signOut();
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('サインインが必要です'), findsOneWidget);
    expect(find.text('応援LTに参加登録するには\nサインインしてください'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(repository.watchedUids, isEmpty);

    await tester.tap(find.bySemanticsLabel('Google でサインイン'));
    await tester.pumpAndSettle();

    expect(find.text('サインインが必要です'), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(repository.watchedUids, ['fake-uid']);
  });

  testWidgets('a signed-in user can register without a profile', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('応援LT参加登録'), findsOneWidget);
    expect(find.text('プロフィールを作成'), findsNothing);
    await submit(tester, ' 123456 ');

    expect(repository.submittedCodes, ['123456']);
    expect(find.text('参加登録が完了しました'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('mirrors each entered digit into its own box', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '4829');
    await tester.pump();

    for (final digit in ['4', '8', '2', '9']) {
      expect(find.text(digit), findsOneWidget);
    }
  });

  testWidgets('validates all six digits before calling the registration endpoint', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await submit(tester, '');
    expect(find.text('6桁の数字を入力してください'), findsOneWidget);
    await submit(tester, '12345');
    expect(find.text('6桁の数字を入力してください'), findsOneWidget);
    expect(repository.submittedCodes, isEmpty);
  });

  testWidgets('uses numeric input and prevents duplicate submits while registering', (tester) async {
    repository.pendingRegistration = Completer<void>();
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.number);
    await tester.enterText(find.byType(TextFormField), '12a3456');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '123456');
    await tester.tap(find.widgetWithText(FilledButton, '参加登録する'));
    await tester.pump();

    expect(find.text('登録中…'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(repository.submittedCodes, ['123456']);

    repository.pendingRegistration!.complete();
    await tester.pumpAndSettle();
    expect(find.text('参加登録が完了しました'), findsOneWidget);
  });

  testWidgets('loads a saved registration without asking for the code again', (tester) async {
    repository.setRegistration(_registration('uid-1'));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('参加登録が完了しました'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(repository.submittedCodes, isEmpty);
    await tester.tap(find.text('アカウントに戻る'));
    await tester.pumpAndSettle();
    expect(find.text('account destination'), findsOneWidget);
    router.go('/account/support-lt');
    await tester.pumpAndSettle();
    expect(find.text('参加登録が完了しました'), findsOneWidget);
  });

  testWidgets('does not carry a previous account registration into another account', (tester) async {
    repository.setRegistration(_registration('uid-1'));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('参加登録が完了しました'), findsOneWidget);

    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('参加登録が完了しました'), findsNothing);
    expect(find.text('応援LTに参加登録するには\nサインインしてください'), findsOneWidget);
    await auth.signInWithGoogle();
    await tester.pumpAndSettle();

    expect(find.text('参加登録が完了しました'), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(repository.watchedUids, ['uid-1', 'fake-uid']);
  });

  for (final (code, message) in [
    ('invalid-argument', '6桁の数字を入力してください'),
    ('not-found', 'コードが正しくありません。運営から案内されたコードを確認してください'),
    ('resource-exhausted', '試行回数が多すぎます。しばらくしてからもう一度お試しください'),
    ('unavailable', '通信に失敗しました。通信状況を確認してもう一度お試しください'),
    ('unauthenticated', 'サインインの有効期限が切れました。もう一度サインインしてください'),
    ('permission-denied', '参加登録が許可されていません。運営に確認してください'),
    ('internal', '参加登録できませんでした。もう一度お試しください'),
  ]) {
    testWidgets('explains $code and lets the attendee retry', (tester) async {
      repository.nextRegisterError = FirebaseFunctionsException(code: code, message: 'private server details');
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      await submit(tester, '123456');

      expect(find.text(message), findsOneWidget);
      expect(find.textContaining('private server details'), findsNothing);
      expect(find.byType(TextFormField), findsOneWidget);
      await submit(tester, '654321');
      expect(repository.submittedCodes, ['123456', '654321']);
      expect(find.text('参加登録が完了しました'), findsOneWidget);
    });
  }

  testWidgets('a failed registration stream can be retried', (tester) async {
    repository.watchError = FirebaseFunctionsException(code: 'unavailable', message: 'unavailable');
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('再試行'), findsOneWidget);

    repository.watchError = null;
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('localizes registration and callable errors in English', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    repository.nextRegisterError = FirebaseFunctionsException(code: 'not-found', message: 'not found');
    await tester.pumpWidget(buildSubject(locale: AppLocale.en));
    await tester.pumpAndSettle();

    expect(find.text('Support LT Registration'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Register participation'));
    await tester.pumpAndSettle();
    expect(find.text('This code is incorrect. Check the code provided by the organizers'), findsOneWidget);
  });
}

SupportLtRegistration _registration(String uid) => SupportLtRegistration(
  uid: uid,
  displayName: 'Attendee',
  registeredAt: DateTime.utc(2026, 11, 13, 7),
);
