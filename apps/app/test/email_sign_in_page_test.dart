import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/page/email_sign_in_page.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';

void main() {
  Widget buildSubject(FakeAuthRepository repository, GoRouter router) => TranslationProvider(
    child: ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
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
      initialLocation: '/account/email',
      routes: [
        GoRoute(
          path: '/account',
          builder: (_, _) => const Scaffold(body: Text('account destination')),
          routes: [
            GoRoute(
              path: 'email',
              builder: (_, _) => const EmailSignInPage(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    return router;
  }

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  testWidgets('validates required fields before submitting', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository, buildRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('サインイン'));
    await tester.pumpAndSettle();

    expect(find.text('メールアドレスを入力してください'), findsOneWidget);
    expect(find.text('パスワードを入力してください'), findsOneWidget);
    expect(repository.calledMethods, isEmpty);
  });

  testWidgets('signs in and returns to the account tab', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);
    final router = buildRouter();

    await tester.pumpWidget(buildSubject(repository, router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'attendee@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('サインイン'));
    await tester.pumpAndSettle();

    expect(repository.calledMethods, ['signInWithEmailAndPassword']);
    expect(repository.lastEmail, 'attendee@example.com');
    expect(repository.lastPassword, 'password123');
    expect(router.routeInformationProvider.value.uri.path, '/account');
    expect(find.text('account destination'), findsOneWidget);
  });

  testWidgets('returns to the previous page only once when the visitor leaves while signing in', (tester) async {
    final repository = FakeAuthRepository()..pendingAction = Completer<void>();
    addTearDown(repository.dispose);
    // サインインカードのある画面から push で開かれたときと同じスタックにする。
    final router = GoRouter(
      initialLocation: '/account/support-lt',
      routes: [
        GoRoute(
          path: '/account',
          builder: (_, _) => const Scaffold(body: Text('account destination')),
          routes: [
            GoRoute(
              path: 'support-lt',
              builder: (_, _) => const Scaffold(body: Text('sign-in card destination')),
            ),
            GoRoute(path: 'email', builder: (_, _) => const EmailSignInPage()),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(buildSubject(repository, router));
    await tester.pumpAndSettle();
    unawaited(router.push<void>('/account/email'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'attendee@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('サインイン'));
    await tester.pump();

    // サインインの完了が、戻る操作の画面遷移中に届く。
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pump();
    repository.pendingAction!.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repository.currentUser, isNotNull);
    expect(find.text('sign-in card destination'), findsOneWidget);
  });

  testWidgets('finishes quietly when sign-in completes after the visitor has left', (tester) async {
    final repository = FakeAuthRepository()..pendingAction = Completer<void>();
    addTearDown(repository.dispose);
    final router = buildRouter();
    await tester.pumpWidget(buildSubject(repository, router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'attendee@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('サインイン'));
    await tester.pump();
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    expect(find.byType(EmailSignInPage), findsNothing);

    repository.pendingAction!.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('account destination'), findsOneWidget);
  });

  testWidgets('creates an account after switching modes', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository, buildRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('アカウントを新規作成する'));
    await tester.pumpAndSettle();

    expect(find.text('既存のアカウントでサインインする'), findsOneWidget);
    expect(find.text('パスワードを再設定する'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('アカウントを作成'));
    await tester.pumpAndSettle();

    expect(repository.calledMethods, ['createUserWithEmailAndPassword']);
    expect(repository.lastEmail, 'new@example.com');
  });

  testWidgets('shows a message when the credentials are wrong', (tester) async {
    final repository = FakeAuthRepository()..nextError = FirebaseAuthException(code: 'wrong-password');
    addTearDown(repository.dispose);
    final router = buildRouter();

    await tester.pumpWidget(buildSubject(repository, router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'attendee@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.tap(find.text('サインイン'));
    await tester.pumpAndSettle();

    expect(find.text('メールアドレスまたはパスワードが正しくありません'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/account/email');
  });

  testWidgets('sends a password reset email', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository, buildRouter()));
    await tester.pumpAndSettle();

    // メールアドレス未入力のときは送信せず入力を促す。
    await tester.tap(find.text('パスワードを再設定する'));
    await tester.pumpAndSettle();
    expect(find.text('メールアドレスを入力してください'), findsOneWidget);
    expect(repository.lastResetEmail, isNull);

    await tester.enterText(find.byType(TextFormField).at(0), 'attendee@example.com');
    await tester.tap(find.text('パスワードを再設定する'));
    await tester.pumpAndSettle();

    expect(repository.lastResetEmail, 'attendee@example.com');
    expect(find.text('パスワード再設定メールを送信しました'), findsOneWidget);
  });
}
