import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/environment.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/page/email_sign_in_page.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
import 'package:app/feature/support_lt/ui/page/support_lt_page.dart';
import 'package:app/feature/support_lt/ui/page/support_lt_scan_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'fake_auth_repository.dart';
import 'fake_mobile_scanner_platform.dart';
import 'fake_support_lt_repository.dart';

const _pagePath = '/account/support-lt';
const _linkPath = '/account/support-lt/123456';
const _invalidCodeMessage = 'コードが正しくありません。会場のQRコードを読み取り直すか、運営に確認してください';

void main() {
  late FakeAuthRepository auth;
  late FakeSupportLtRepository repository;
  late GoRouter router;

  final originalPlatform = MobileScannerPlatform.instance;
  setUpAll(() async {
    MobileScannerPlatform.instance = FakeMobileScannerPlatform();
    await AppLocale.en.build();
  });
  tearDownAll(() => MobileScannerPlatform.instance = originalPlatform);

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    auth = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    repository = FakeSupportLtRepository();
    addTearDown(auth.dispose);
    addTearDown(repository.dispose);
  });

  Widget buildSubject({AppLocale locale = AppLocale.ja, String location = _pagePath}) {
    router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/account',
          builder: (_, _) => const Scaffold(body: Text('account destination')),
          routes: [
            GoRoute(path: 'email', builder: (_, _) => const EmailSignInPage()),
            GoRoute(path: 'support-lt', builder: (_, _) => const SupportLtPage()),
            GoRoute(
              path: 'support-lt/:code',
              builder: (_, state) => SupportLtPage(linkCode: state.pathParameters['code']),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    return TranslationProvider(
      child: ProviderScope(
        retry: (retryCount, error) => null,
        overrides: [
          environmentProvider.overrideWithValue(Environment.fromEnvironment().copyWith(flavor: Flavor.production)),
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
  }

  /// The code entry sits below the scan button, outside the test viewport.
  Future<void> tapRegister(WidgetTester tester, {String label = '参加登録する'}) async {
    final button = find.widgetWithText(FilledButton, label);
    await tester.ensureVisible(button);
    await tester.tap(button);
  }

  Future<void> submit(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextFormField), code);
    await tapRegister(tester);
    await tester.pumpAndSettle();
  }

  Future<void> openScanner(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'QRコードを読み取る'));
    await tester.pumpAndSettle();
  }

  void detect(WidgetTester tester, String rawValue) {
    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    scanner.onDetect!(BarcodeCapture(barcodes: [Barcode(rawValue: rawValue)]));
  }

  /// Advances past the auth and registration lookups while a pending request
  /// keeps its progress indicator animating, which `pumpAndSettle` waits on.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  String enteredCode(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!.text;

  FirebaseFunctionsException rejectedCode() => FirebaseFunctionsException(code: 'not-found', message: 'not found');

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

  testWidgets('offers the QR code scan first and the code entry as a fallback', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('会場に表示されたQRコードを読み取って、応援LTへの参加を登録してください'), findsOneWidget);
    expect(find.text('QRコードを読み取れない場合'), findsOneWidget);
    expect(
      tester.getTopLeft(find.widgetWithText(FilledButton, 'QRコードを読み取る')).dy,
      lessThan(tester.getTopLeft(find.byType(TextFormField)).dy),
    );
    expect(repository.submittedCodes, isEmpty);
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
    expect(enteredCode(tester), '123456');
    await tapRegister(tester);
    await tester.pump();

    expect(find.text('登録中…'), findsOneWidget);
    for (final button in tester.widgetList<FilledButton>(find.byType(FilledButton))) {
      expect(button.onPressed, isNull);
    }
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
    router.go(_pagePath);
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
    ('not-found', _invalidCodeMessage),
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
    repository.nextRegisterError = rejectedCode();
    await tester.pumpWidget(buildSubject(locale: AppLocale.en));
    await tester.pumpAndSettle();

    expect(find.text('Support LT Registration'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Scan the QR code'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tapRegister(tester, label: 'Register participation');
    await tester.pumpAndSettle();
    expect(
      find.text('This code is incorrect. Scan the QR code at the venue again or ask the organizers'),
      findsOneWidget,
    );
  });

  group('QR code scan', () {
    testWidgets('registers with the code in the scanned venue link', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      await openScanner(tester);
      expect(find.byType(SupportLtScanPage), findsOneWidget);

      detect(tester, '$productionAppOrigin/account/support-lt/123456');
      await tester.pumpAndSettle();

      expect(find.byType(SupportLtScanPage), findsNothing);
      expect(repository.submittedCodes, ['123456']);
      expect(find.text('参加登録が完了しました'), findsOneWidget);
    });

    testWidgets('submits once and stays on the page when the camera reports the code repeatedly', (tester) async {
      repository.nextRegisterError = rejectedCode();
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      await openScanner(tester);

      for (var detection = 0; detection < 3; detection++) {
        detect(tester, '$productionAppOrigin/account/support-lt/123456');
      }
      await tester.pumpAndSettle();

      expect(repository.submittedCodes, ['123456']);
      expect(find.byType(SupportLtScanPage), findsNothing);
      expect(find.byType(SupportLtPage), findsOneWidget);
      expect(find.text(_invalidCodeMessage), findsOneWidget);
      expect(enteredCode(tester), '123456');
    });

    testWidgets('lets the attendee scan again after a rejected code', (tester) async {
      repository.nextRegisterError = rejectedCode();
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      await openScanner(tester);
      detect(tester, '123456');
      await tester.pumpAndSettle();
      expect(find.text(_invalidCodeMessage), findsOneWidget);

      await openScanner(tester);
      detect(tester, '654321');
      await tester.pumpAndSettle();

      expect(repository.submittedCodes, ['123456', '654321']);
      expect(find.text('参加登録が完了しました'), findsOneWidget);
    });

    testWidgets('closing the scanner without a QR code does not call the registration endpoint', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      await openScanner(tester);

      detect(tester, 'v1.other-uid.9999999999.deadbeef');
      await tester.pumpAndSettle();
      expect(find.byType(SupportLtScanPage), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(SupportLtScanPage), findsNothing);
      expect(repository.submittedCodes, isEmpty);
      expect(enteredCode(tester), isEmpty);
    });

    testWidgets('ignores a QR code detected while the scanner is closing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      await openScanner(tester);

      // The camera keeps reporting codes until the closing transition ends.
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      detect(tester, '123456');
      await tester.pumpAndSettle();

      expect(find.byType(SupportLtScanPage), findsNothing);
      expect(find.byType(SupportLtPage), findsOneWidget);
      expect(repository.submittedCodes, isEmpty);
    });

    testWidgets('discards a code scanned after the attendee was signed out', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      await openScanner(tester);

      await auth.signOut();
      await tester.pumpAndSettle();
      detect(tester, '123456');
      await tester.pumpAndSettle();

      expect(repository.submittedCodes, isEmpty);
      expect(tester.takeException(), isNull);
      expect(find.text('応援LTに参加登録するには\nサインインしてください'), findsOneWidget);
    });
  });

  group('QR code link', () {
    testWidgets('registers without a tap and returns to the account page on back', (tester) async {
      await tester.pumpWidget(buildSubject(location: _linkPath));
      await tester.pumpAndSettle();

      expect(repository.submittedCodes, ['123456']);
      expect(find.text('参加登録が完了しました'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('account destination'), findsOneWidget);
    });

    testWidgets('does not submit a link without a six-digit code', (tester) async {
      await tester.pumpWidget(buildSubject(location: '/account/support-lt/12345a'));
      await tester.pumpAndSettle();

      expect(find.text('このリンクは無効です。会場のQRコードを読み取り直してください'), findsOneWidget);
      expect(repository.submittedCodes, isEmpty);
      expect(enteredCode(tester), isEmpty);
    });

    testWidgets('does not call the endpoint for an attendee who is already registered', (tester) async {
      repository.setRegistration(_registration('uid-1'));
      await tester.pumpWidget(buildSubject(location: _linkPath));
      await tester.pumpAndSettle();

      expect(find.text('参加登録が完了しました'), findsOneWidget);
      expect(repository.submittedCodes, isEmpty);
    });

    testWidgets('registers a signed-out visitor after a Google sign-in on the page', (tester) async {
      repository.registeringUid = 'fake-uid';
      await auth.signOut();
      await tester.pumpWidget(buildSubject(location: _linkPath));
      await tester.pumpAndSettle();
      expect(repository.submittedCodes, isEmpty);

      await tester.tap(find.bySemanticsLabel('Google でサインイン'));
      await tester.pumpAndSettle();

      expect(repository.submittedCodes, ['123456']);
      expect(find.text('参加登録が完了しました'), findsOneWidget);
    });

    testWidgets('registers a signed-out visitor who returns from the email sign-in page', (tester) async {
      repository.registeringUid = 'fake-uid';
      await auth.signOut();
      await tester.pumpWidget(buildSubject(location: _linkPath));
      await tester.pumpAndSettle();

      await tester.tap(find.text('メールアドレスでサインイン'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'attendee@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('サインイン'));
      await tester.pumpAndSettle();

      expect(find.byType(EmailSignInPage), findsNothing);
      expect(repository.submittedCodes, ['123456']);
      expect(find.text('参加登録が完了しました'), findsOneWidget);
    });

    testWidgets('submits a rejected code only once when the form comes back, leaving the retry to a tap', (
      tester,
    ) async {
      repository.nextRegisterError = rejectedCode();
      await tester.pumpWidget(buildSubject(location: _linkPath));
      await tester.pumpAndSettle();
      expect(repository.submittedCodes, ['123456']);
      expect(find.text(_invalidCodeMessage), findsOneWidget);

      repository.emitWatchError(FirebaseFunctionsException(code: 'unavailable', message: 'unavailable'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();

      expect(enteredCode(tester), '123456');
      expect(repository.submittedCodes, ['123456']);

      await tapRegister(tester);
      await tester.pumpAndSettle();
      expect(repository.submittedCodes, ['123456', '123456']);
      expect(find.text('参加登録が完了しました'), findsOneWidget);
    });

    testWidgets('does not resubmit for the same account signing in again', (tester) async {
      repository.nextRegisterError = rejectedCode();
      await auth.signOut();
      await tester.pumpWidget(buildSubject(location: _linkPath));
      await tester.pumpAndSettle();
      await auth.signInWithGoogle();
      await tester.pumpAndSettle();
      expect(repository.submittedCodes, ['123456']);

      await auth.signOut();
      await tester.pumpAndSettle();
      await auth.signInWithGoogle();
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(repository.submittedCodes, ['123456']);
    });

    testWidgets('submits again for another account that signs in on the same page', (tester) async {
      repository.nextRegisterError = rejectedCode();
      await tester.pumpWidget(buildSubject(location: _linkPath));
      await tester.pumpAndSettle();
      expect(repository.submittedCodes, ['123456']);

      repository.registeringUid = 'fake-uid';
      await auth.signOut();
      await tester.pumpAndSettle();
      await auth.signInWithGoogle();
      await tester.pumpAndSettle();

      expect(repository.watchedUids, ['uid-1', 'fake-uid']);
      expect(repository.submittedCodes, ['123456', '123456']);
      expect(find.text('参加登録が完了しました'), findsOneWidget);
    });

    testWidgets('submits a different link opened next without the previous result', (tester) async {
      repository.nextRegisterError = rejectedCode();
      await tester.pumpWidget(buildSubject(location: '/account/support-lt/111111'));
      await tester.pumpAndSettle();
      expect(find.text(_invalidCodeMessage), findsOneWidget);

      repository.pendingRegistration = Completer<void>();
      router.go('/account/support-lt/222222');
      await pumpFrames(tester);

      expect(repository.submittedCodes, ['111111', '222222']);
      expect(find.text(_invalidCodeMessage), findsNothing);
      expect(enteredCode(tester), '222222');

      repository.pendingRegistration!.complete();
      await tester.pumpAndSettle();
      expect(find.text('参加登録が完了しました'), findsOneWidget);
    });

    testWidgets('ignores the response when the attendee leaves during registration', (tester) async {
      repository.pendingRegistration = Completer<void>();
      await tester.pumpWidget(buildSubject(location: _linkPath));
      await pumpFrames(tester);
      expect(find.text('登録中…'), findsOneWidget);

      router.go('/account');
      await pumpFrames(tester);
      repository.pendingRegistration!.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('account destination'), findsOneWidget);
      expect(repository.submittedCodes, ['123456']);
    });
  });
}

SupportLtRegistration _registration(String uid) => SupportLtRegistration(
  uid: uid,
  displayName: 'Attendee',
  registeredAt: DateTime.utc(2026, 11, 13, 7),
);
