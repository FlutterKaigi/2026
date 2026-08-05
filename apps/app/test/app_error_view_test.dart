import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a permission message and retries', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: AppErrorView(
              error: FirebaseException(
                plugin: 'cloud_firestore',
                code: 'permission-denied',
              ),
              onRetry: () => retryCount++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('データを読み込めませんでした'), findsOneWidget);
    expect(
      find.text('この情報を表示する権限がありません。FlutterKaigi スタッフへお問い合わせください。'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('困った表情のダシュマル'), findsOneWidget);

    await tester.tap(find.text('再試行'));
    expect(retryCount, 1);
  });

  testWidgets('shows a connection message without naming Firebase', (
    tester,
  ) async {
    await _pumpError(
      tester,
      FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      ),
    );

    expect(
      find.text('通信状況を確認して、しばらくしてからもう一度お試しください。'),
      findsOneWidget,
    );
    expect(find.textContaining('Firebase'), findsNothing);
  });

  testWidgets('shows a timeout message for deadline exceeded', (tester) async {
    await _pumpError(
      tester,
      FirebaseException(
        plugin: 'cloud_firestore',
        code: 'deadline-exceeded',
      ),
    );

    expect(
      find.text('読み込みに時間がかかっています。もう一度お試しください。'),
      findsOneWidget,
    );
  });

  testWidgets('shows a generic message for non-Firebase errors', (
    tester,
  ) async {
    await _pumpError(tester, StateError('unexpected'));

    expect(
      find.text('通信状況を確認して、もう一度お試しください。'),
      findsOneWidget,
    );
    expect(find.textContaining('unexpected'), findsNothing);
  });
}

Future<void> _pumpError(WidgetTester tester, Object error) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        locale: const Locale('ja'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: AppErrorView(error: error, onRetry: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
