import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/page/account_page.dart';
import 'package:app/feature/auth/ui/widget/apple_sign_in_button.dart';
import 'package:app/feature/auth/ui/widget/google_sign_in_button.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';

void main() {
  Widget buildSubject(FakeAuthRepository repository) => TranslationProvider(
    child: ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: const Locale('ja'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const AccountPage(),
      ),
    ),
  );

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  testWidgets('signs in with Google from the signed-out view', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Google でサインイン'), findsOneWidget);
    expect(find.text('Appleでサインイン'), findsOneWidget);
    expect(find.text('メールアドレスでサインイン'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Google でサインイン'));
    await tester.pumpAndSettle();

    expect(repository.calledMethods, ['signInWithGoogle']);
    expect(find.text('Google User'), findsOneWidget);
    expect(find.text('google@example.com'), findsOneWidget);
    expect(find.text('サインイン中'), findsOneWidget);
    expect(find.text('サインアウト'), findsOneWidget);
  });

  testWidgets('keeps all sign-in method buttons at the same size', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository));
    await tester.pumpAndSettle();

    final googleSize = tester.getSize(find.byType(GoogleSignInButton));
    final appleSize = tester.getSize(find.byType(AppleSignInButton));
    final emailSize = tester.getSize(
      find.widgetWithText(OutlinedButton, 'メールアドレスでサインイン'),
    );

    expect(googleSize, const Size(375, 48));
    expect(appleSize, googleSize);
    expect(emailSize, googleSize);
  });

  testWidgets('uses the same typography for every sign-in method', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository));
    await tester.pumpAndSettle();

    TextStyle effectiveStyle(String label) {
      final finder = find.text(label);
      final text = tester.widget<Text>(finder);
      return DefaultTextStyle.of(tester.element(finder)).style.merge(text.style);
    }

    final styles = [
      effectiveStyle('Google でサインイン'),
      effectiveStyle('Appleでサインイン'),
      effectiveStyle('メールアドレスでサインイン'),
    ];
    for (final style in styles) {
      expect(style.fontSize, 14);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.height, 20 / 14);
    }
  });

  testWidgets('shows a message when sign-in fails', (tester) async {
    final repository = FakeAuthRepository()..nextError = FirebaseAuthException(code: 'network-request-failed');
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Appleでサインイン'));
    await tester.pumpAndSettle();

    expect(
      find.text('通信に失敗しました。通信状況を確認してもう一度お試しください'),
      findsOneWidget,
    );
    expect(find.text('Appleでサインイン'), findsOneWidget);
  });

  testWidgets('stays silent when the user cancels sign-in', (tester) async {
    final repository = FakeAuthRepository()..nextError = FirebaseAuthException(code: 'canceled');
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Google でサインイン'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.bySemanticsLabel('Google でサインイン'), findsOneWidget);
  });

  testWidgets('signs out from the signed-in view', (tester) async {
    final repository = FakeAuthRepository(
      initialUser: FakeUser(email: 'attendee@example.com'),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository));
    await tester.pumpAndSettle();

    expect(find.text('attendee@example.com'), findsOneWidget);
    expect(find.text('サインイン中'), findsOneWidget);

    await tester.tap(find.text('サインアウト'));
    await tester.pumpAndSettle();

    expect(repository.calledMethods, ['signOut']);
    expect(find.bySemanticsLabel('Google でサインイン'), findsOneWidget);
  });

  testWidgets('deletes a Google account after confirmation', (tester) async {
    final repository = FakeAuthRepository(
      initialUser: FakeUser(
        email: 'attendee@example.com',
        providerIds: const ['google.com'],
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('アカウントを削除'));
    await tester.pumpAndSettle();

    expect(find.text('アカウントを削除しますか?'), findsOneWidget);

    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(repository.calledMethods, ['deleteAccount']);
    expect(repository.lastDeletePassword, isNull);
    expect(find.text('アカウントを削除しました'), findsOneWidget);
    expect(find.bySemanticsLabel('Google でサインイン'), findsOneWidget);
  });

  testWidgets('asks for the current password before deleting an email account', (tester) async {
    final repository = FakeAuthRepository(
      initialUser: FakeUser(
        email: 'attendee@example.com',
        providerIds: const ['password'],
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('アカウントを削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(find.text('パスワードの確認'), findsOneWidget);
    expect(repository.calledMethods, isEmpty);

    await tester.enterText(find.byType(TextField), 'password123');
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(repository.calledMethods, ['deleteAccount']);
    expect(repository.lastDeletePassword, 'password123');
    expect(find.bySemanticsLabel('Google でサインイン'), findsOneWidget);
  });

  testWidgets('keeps the account when deletion is canceled', (tester) async {
    final repository = FakeAuthRepository(
      initialUser: FakeUser(
        email: 'attendee@example.com',
        providerIds: const ['google.com'],
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(buildSubject(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('アカウントを削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(repository.calledMethods, isEmpty);
    expect(find.text('attendee@example.com'), findsOneWidget);
  });
}
