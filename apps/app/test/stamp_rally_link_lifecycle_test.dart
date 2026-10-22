import 'dart:async';

import 'package:app/core/constants/app_links.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/remote_config/event_features_provider.dart';
import 'package:app/core/router/launch_route.dart';
import 'package:app/core/router/router.dart' as app_router;
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:app/feature/stamp_rally/data/stamp_rally_provider.dart';
import 'package:app/feature/stamp_rally/ui/page/stamp_rally_link_page.dart';
import 'package:app/feature/stamp_rally/ui/page/stamp_rally_scan_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'fake_auth_repository.dart';
import 'fake_mobile_scanner_platform.dart';

final token = 'ab' * 32;
final time = DateTime.utc(2026, 11, 13, 5);

void main() {
  const launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');
  late List<Uri> launched;
  late bool launchSucceeds;
  late FakeAuthRepository auth;
  late _Repository repository;
  late GoRouter router;
  setUp(() {
    launched = [];
    launchSucceeds = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      launcherChannel,
      (call) async {
        expect(call.method, 'launch');
        final arguments = call.arguments as Map;
        launched.add(Uri.parse(arguments['url'] as String));
        expect(arguments['useWebView'], isFalse);
        expect(arguments['useSafariVC'], isFalse);
        return launchSucceeds;
      },
    );
    LocaleSettings.setLocaleSync(AppLocale.ja);
    auth = FakeAuthRepository(initialUser: FakeUser(uid: 'attendee'));
    repository = _Repository();
    router = GoRouter(
      initialLocation: '/s/$token',
      routes: [
        GoRoute(
          path: '/other',
          builder: (_, _) => const Scaffold(body: Text('other')),
        ),
        GoRoute(
          path: '/s/:token',
          builder: (_, state) => StampRallyLinkPage(token: state.pathParameters['token']!),
        ),
      ],
    );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(launcherChannel, null);
    router.dispose();
    auth.dispose();
  });

  Future<void> show(WidgetTester tester, {bool settle = true}) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            stampRallyRepositoryProvider.overrideWithValue(repository),
            sponsorListProvider.overrideWith((_) => Stream.value(const <Sponsor>[])),
            appleSignInAvailabilityProvider.overrideWithValue(false),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: AppLocale.ja.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('opens Luma after a new redemption succeeds and keeps the manual button', (tester) async {
    repository.delayFirst = Completer<void>();
    await show(tester, settle: false);
    expect(repository.calls, 1);
    expect(launched, isEmpty);

    repository.delayFirst!.complete();
    await tester.pumpAndSettle();
    expect(launched, [Uri.parse(AppLinks.lumaEvent)]);
    expect(find.text('#1 の景品を受け取れます'), findsOneWidget);
    final button = find.text('Lumaでチケットを開く');
    expect(button, findsOneWidget);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(launched, [Uri.parse(AppLinks.lumaEvent), Uri.parse(AppLinks.lumaEvent)]);
    expect(repository.calls, 1);
  });

  testWidgets('a failed automatic launch keeps the result and allows manual retry', (tester) async {
    launchSucceeds = false;
    await show(tester);
    expect(launched, [Uri.parse(AppLinks.lumaEvent)]);
    expect(find.text(t.links.openError), findsOneWidget);
    expect(find.text('#1 の景品を受け取れます'), findsOneWidget);

    launchSucceeds = true;
    final button = find.text('Lumaでチケットを開く');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(launched, [Uri.parse(AppLinks.lumaEvent), Uri.parse(AppLinks.lumaEvent)]);
    expect(repository.calls, 1);
  });

  for (final kind in ['stamp', 'thanks']) {
    testWidgets('a $kind QR does not open Luma', (tester) async {
      repository.stamp = kind == 'stamp';
      repository.thanks = kind == 'thanks';
      await show(tester);
      expect(repository.calls, 1);
      expect(launched, isEmpty);
    });
  }

  testWidgets('a failed redemption does not open Luma', (tester) async {
    repository.nextError = FirebaseFunctionsException(code: 'unavailable', message: 'Offline');
    await show(tester);
    expect(find.text('通信できませんでした。電波の良い場所でもう一度お試しください'), findsOneWidget);
    expect(launched, isEmpty);
  });

  testWidgets('a delayed redemption does not open Luma over another page or on return', (tester) async {
    repository.delayFirst = Completer<void>();
    await show(tester, settle: false);
    unawaited(router.push<void>('/other'));
    await tester.pumpAndSettle();
    repository.delayFirst!.complete();
    await tester.pumpAndSettle();
    expect(find.text('other'), findsOneWidget);
    expect(launched, isEmpty);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('#1 の景品を受け取れます'), findsOneWidget);
    expect(find.text('Lumaでチケットを開く'), findsOneWidget);
    expect(repository.calls, 1);
    expect(launched, isEmpty);
  });

  testWidgets('a previous account delayed redemption does not open Luma', (tester) async {
    repository.delayFirst = Completer<void>();
    await show(tester, settle: false);
    expect(repository.calls, 1);
    await auth.signOut();
    await tester.pumpAndSettle();
    await auth.signInWithGoogle();
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    repository.delayFirst!.complete();
    await tester.pumpAndSettle();
    expect(find.text('新たに交換できる景品はありません'), findsOneWidget);
    expect(launched, isEmpty);
  });

  testWidgets('an OS link replacing an in-app scan result sends only one fresh scan', (tester) async {
    final previousPlatform = MobileScannerPlatform.instance;
    MobileScannerPlatform.instance = FakeMobileScannerPlatform();
    addTearDown(() => MobileScannerPlatform.instance = previousPlatform);
    GoRouter.optionURLReflectsImperativeAPIs = true;
    router.dispose();
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(path: '/scan', builder: (_, _) => const StampRallyScanPage()),
        GoRoute(
          path: '/s/:token',
          builder: (_, state) => StampRallyLinkPage(token: state.pathParameters['token']!),
        ),
      ],
    );
    await show(tester);
    unawaited(router.push('/scan'));
    await tester.pumpAndSettle();
    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    scanner.onDetect!(BarcodeCapture(barcodes: [Barcode(rawValue: 'https://2026-app.flutterkaigi.jp/s/$token')]));
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
    await tester.binding.handlePushRoute('/s/$token');
    await tester.pumpAndSettle();
    expect(repository.calls, 2, reason: 'Only the new current route may rescan; the departing result must not redeem');
  });

  testWidgets('refresh after an already-loaded auth state does not rescan', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        stampRallyRepositoryProvider.overrideWithValue(repository),
        sponsorListProvider.overrideWith((_) => Stream.value(const <Sponsor>[])),
        appleSignInAvailabilityProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);
    final authSubscription = container.listen(authStateChangesProvider, (_, _) {});
    addTearDown(authSubscription.close);
    await tester.pump();
    expect(container.read(authStateChangesProvider).hasValue, isTrue);
    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: AppLocale.ja.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
    router.refresh();
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
    expect(find.text('#1 の景品を受け取れます'), findsOneWidget);
  });

  testWidgets('a covered result is not left loading after the same link is pushed and popped', (tester) async {
    await show(tester);
    unawaited(router.push<void>('/s/$token'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    router.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(repository.calls, 2, reason: 'Popping the covering page is not a new QR scan');
  });

  testWidgets('same-frame duplicate QR deliveries make one fresh scan', (tester) async {
    await show(tester);
    repository.delayNext = Completer<void>();
    await tester.binding.handlePushRoute('/s/$token');
    await tester.binding.handlePushRoute('/s/$token');
    await tester.pump();
    await tester.pump();
    expect(repository.calls, 2);
    expect(find.text('#1 の景品を受け取れます'), findsNothing);
    repository.delayNext!.complete();
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('新たに交換できる景品はありません'), findsOneWidget);
  });

  testWidgets('same reward universal link refreshes claimed state', (tester) async {
    await show(tester);
    expect(repository.calls, 1);
    expect(find.text('#1 の景品を受け取れます'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.binding.handlePushRoute('/s/$token');
    await tester.pumpAndSettle();
    expect(repository.calls, 2, reason: 'A new OS camera scan should recheck whether the prize is already claimed');
    expect(find.text('新たに交換できる景品はありません'), findsOneWidget);
    expect(launched, [Uri.parse(AppLinks.lumaEvent)], reason: 'An already redeemed reward must not open Luma again');
  });

  testWidgets('actual app router rechecks crane approval when the same link is reopened', (tester) async {
    repository.thanks = true;
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        stampRallyRepositoryProvider.overrideWithValue(repository),
        sponsorListProvider.overrideWith((_) => Stream.value(const <Sponsor>[])),
        appleSignInAvailabilityProvider.overrideWithValue(false),
        launchRouteProvider.overrideWithValue(Uri.parse('/s/$token')),
        eventFeaturesEnabledProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);
    router.dispose();
    router = container.read(app_router.routerProvider);
    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: AppLocale.ja.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
    expect(find.text('クレーンゲームに挑戦できます'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.binding.handlePushRoute('/s/$token');
    await tester.pumpAndSettle();
    expect(repository.calls, 2, reason: 'Actual app router must recheck the same scanned QR');
    expect(find.text('クレーンゲームは挑戦済みです'), findsOneWidget);
  });

  testWidgets('different QR universal link is dispatched to the screen', (tester) async {
    repository.thanks = true;
    await show(tester);
    expect(repository.calls, 1);
    await tester.binding.handlePushRoute('/s/${'cd' * 32}');
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('クレーンゲームは挑戦済みです'), findsOneWidget);
  });

  testWidgets('reopening a booth QR after staff opens the rally must recover a closed error', (tester) async {
    repository.stamp = true;
    repository.nextError = FirebaseFunctionsException(code: 'failed-precondition', message: 'The rally is closed');
    await show(tester);
    expect(repository.calls, 1);
    expect(find.text('現在スタンプは獲得できません'), findsOneWidget);
    expect(find.text('もう一度試す'), findsNothing);
    // Staff has now opened the rally; a fresh server scan would succeed.
    await tester.binding.handlePushRoute('/s/$token');
    await tester.pumpAndSettle();
    expect(repository.calls, 2, reason: 'Opening the same booth QR after reception starts must retry');
    expect(find.text('スタンプを獲得しました！'), findsOneWidget);
  });

  testWidgets('resuming and refreshing the router do not perform another redemption', (tester) async {
    await show(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    router.refresh();
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
    expect(find.text('#1 の景品を受け取れます'), findsOneWidget);
    expect(launched, [Uri.parse(AppLinks.lumaEvent)], reason: 'Returning from Luma must not launch it again');
  });

  testWidgets('reopening a QR hides its old approval and coalesces duplicate links while checking', (tester) async {
    await show(tester);
    repository.delayNext = Completer<void>();
    await tester.binding.handlePushRoute('/s/$token');
    await tester.pump();
    await tester.pump();
    expect(repository.calls, 2);
    expect(find.text('#1 の景品を受け取れます'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.binding.handlePushRoute('/s/$token');
    await tester.binding.handlePushRoute('/s/$token');
    await tester.pump();
    expect(repository.calls, 2);
    repository.delayNext!.complete();
    await tester.pumpAndSettle();
    expect(find.text('新たに交換できる景品はありません'), findsOneWidget);
  });

  testWidgets('signing out and into a different account recreates the scan', (tester) async {
    repository.thanks = true;
    await show(tester);
    expect(find.text('クレーンゲームに挑戦できます'), findsOneWidget);
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('クレーンゲームに挑戦できます'), findsNothing);
    expect(find.byType(SignInCard), findsOneWidget);
    await auth.signInWithGoogle();
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('クレーンゲームは挑戦済みです'), findsOneWidget);
  });

  testWidgets('previous account delayed success cannot overwrite the new account result', (tester) async {
    repository.thanks = true;
    repository.delayFirst = Completer<void>();
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            stampRallyRepositoryProvider.overrideWithValue(repository),
            appleSignInAvailabilityProvider.overrideWithValue(false),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: AppLocale.ja.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(repository.calls, 1);
    await auth.signOut();
    await tester.pumpAndSettle();
    await auth.signInWithGoogle();
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('クレーンゲームは挑戦済みです'), findsOneWidget);
    repository.delayFirst!.complete();
    await tester.pumpAndSettle();
    expect(find.text('クレーンゲームは挑戦済みです'), findsOneWidget);
    expect(find.text('クレーンゲームに挑戦できます'), findsNothing);
  });

  testWidgets('reward response loss preserves redemption history after retry', (tester) async {
    repository.dropFirstResponse = true;
    await show(tester);
    expect(find.text('通信できませんでした。電波の良い場所でもう一度お試しください'), findsOneWidget);
    await tester.tap(find.text('もう一度試す'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('新たに交換できる景品はありません'), findsOneWidget);
    expect(find.text('#1 の景品を受け取れます'), findsNothing);
    expect(find.textContaining('#1 交換日時'), findsOneWidget);
    expect(launched, isEmpty);
  });

  testWidgets('same crane game universal link refreshes claimed state', (tester) async {
    repository.thanks = true;
    await show(tester);
    expect(repository.calls, 1);
    expect(find.text('クレーンゲームに挑戦できます'), findsOneWidget);
    await tester.binding.handlePushRoute('/s/$token');
    await tester.pumpAndSettle();
    expect(
      repository.calls,
      2,
      reason: 'A new OS camera scan should recheck whether the crane game has already been played',
    );
    expect(find.text('クレーンゲームは挑戦済みです'), findsOneWidget);
  });
}

class _Repository implements StampRallyRepository {
  int calls = 0;
  bool dropFirstResponse = false;
  bool thanks = false;
  bool stamp = false;
  Exception? nextError;
  Completer<void>? delayFirst;
  Completer<void>? delayNext;
  @override
  Future<StampRallyScanResult> scan(String token) async {
    calls++;
    final attempt = calls;
    if (delayNext != null) {
      await delayNext!.future;
    }
    if (attempt == 1 && delayFirst != null) {
      await delayFirst!.future;
    }
    final error = nextError;
    nextError = null;
    if (error != null) {
      throw error;
    }
    if (calls == 1 && dropFirstResponse) {
      throw FirebaseFunctionsException(code: 'unavailable', message: 'Response dropped after server commit');
    }
    if (thanks) {
      return StampRallyThanksCardResult(alreadyRedeemed: attempt > 1, redeemedAt: time);
    }
    if (stamp) {
      return StampRallyStampResult(
        sponsorId: 'booth',
        alreadyAcquired: false,
        acquiredAt: time,
        stampCount: 1,
        newCheckpoints: [],
        checkpoints: [7, 14, 22],
      );
    }
    return StampRallyRewardResult(
      redeemedCheckpoints: attempt == 1 ? [1] : [],
      redeemedAt: attempt == 1 ? time : null,
      stampCount: 7,
      checkpoints: [7, 14, 22],
      rewardsRedeemedAt: {1: time},
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
