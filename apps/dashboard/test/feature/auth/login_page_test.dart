import 'dart:async';

import 'package:dashboard/feature/auth/data/provider/auth_repository.dart';
import 'package:dashboard/feature/auth/ui/auth/page/login_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Future<_Auth> showLoginPage(WidgetTester tester) async {
    final auth = _Auth();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    return auth;
  }

  testWidgets('explains a failed sign-in and allows another attempt', (tester) async {
    final auth = await showLoginPage(tester);

    await tester.tap(find.text('Sign in with Google'));
    await tester.pump();
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNull);
    auth.pendingSignIn.completeError(StateError('popup closed'));
    await tester.pumpAndSettle();

    expect(find.text('サインインに失敗しました'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNotNull);
  });

  for (final outcome in ['succeeds', 'fails']) {
    testWidgets('finishes quietly when sign-in $outcome after the page was replaced', (tester) async {
      final auth = await showLoginPage(tester);
      await tester.tap(find.text('Sign in with Google'));
      await tester.pump();

      // The router replaces the login page as soon as the auth state changes.
      await tester.pumpWidget(const SizedBox());
      if (outcome == 'fails') {
        auth.pendingSignIn.completeError(StateError('popup closed'));
      } else {
        auth.pendingSignIn.complete();
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}

class _Auth extends Fake implements AuthRepository {
  final pendingSignIn = Completer<void>();

  @override
  Future<void> signInWithGoogle() => pendingSignIn.future;
}
