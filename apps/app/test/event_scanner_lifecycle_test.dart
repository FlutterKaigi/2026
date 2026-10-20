import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/quiz/ui/page/quiz_check_in_scan_page.dart';
import 'package:app/feature/stamp_rally/ui/page/stamp_rally_scan_page.dart';
import 'package:app/feature/support_lt/ui/page/support_lt_scan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'fake_auth_repository.dart';

void main() {
  late MobileScannerPlatform oldPlatform;
  late _Camera camera;
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    TestWidgetsFlutterBinding.ensureInitialized().handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    oldPlatform = MobileScannerPlatform.instance;
    camera = _Camera();
    MobileScannerPlatform.instance = camera;
  });
  tearDown(() {
    MobileScannerPlatform.instance = oldPlatform;
  });
  final scenarios = <(String, Widget Function())>[
    ('stamp rally', () => const StampRallyScanPage()),
    ('support LT', () => const SupportLtScanPage()),
    ('quiz check-in', () => const QuizCheckInScanPage(eventId: 'audit-event')),
  ];
  Future<GlobalKey<NavigatorState>> show(WidgetTester tester, Widget Function() page, {bool settle = true}) async {
    final auth = FakeAuthRepository(initialUser: FakeUser(uid: 'attendee'));
    addTearDown(auth.dispose);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
          ],
          child: MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(body: Text('home')),
            locale: AppLocale.ja.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => page()));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
    return navigator;
  }

  Future<void> platformLifecycle(WidgetTester tester, AppLifecycleState state) async {
    // Use the engine channel so paused → resumed also synthesizes hidden.
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
      (_) {},
    );
  }

  for (final (name, page) in scenarios) {
    testWidgets('$name does not treat a permission prompt background return as a Settings visit', (tester) async {
      camera.permissionGranted = false;
      camera.permissionGate = Completer<void>();
      await show(tester, page, settle: false);
      expect(camera.starts, 1);
      await platformLifecycle(tester, AppLifecycleState.paused);
      camera.permissionGate!.complete();
      await tester.pump();
      await platformLifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(camera.starts, 1, reason: 'The return-path hidden state is not a new background visit');
      expect(find.textContaining('カメラを利用できません'), findsOneWidget);
      await platformLifecycle(tester, AppLifecycleState.paused);
      camera.permissionGranted = true;
      await platformLifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(camera.starts, 2);
      expect(camera.active, isTrue);
      expect(find.textContaining('カメラを利用できません'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('$name does not immediately request camera permission again after denial', (tester) async {
      camera.permissionGranted = false;
      await show(tester, page);
      expect(camera.starts, 1);
      for (var dialogReturn = 0; dialogReturn < 2; dialogReturn++) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();
        expect(camera.starts, 1);
      }
      expect(find.textContaining('カメラを利用できません'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('$name does not request denied permission when another route is dismissed', (tester) async {
      camera.permissionGranted = false;
      final navigator = await show(tester, page);
      navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('cover'))));
      await tester.pumpAndSettle();
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(camera.starts, 1);
      expect(find.textContaining('カメラを利用できません'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('$name requires another background visit after a permission retry is denied', (tester) async {
      camera.permissionGranted = false;
      await show(tester, page);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(camera.starts, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(camera.starts, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      camera.permissionGranted = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(camera.starts, 3);
      expect(find.textContaining('カメラを利用できません'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('$name scanner retries when returning after granting camera permission in Settings', (tester) async {
      camera.permissionGranted = false;
      await show(tester, page);
      expect(camera.starts, 1);
      expect(find.textContaining('カメラを利用できません'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      camera.permissionGranted = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(
        camera.starts,
        2,
        reason:
            'The screen tells users to grant permission in Settings, but returning must restart the failed controller',
      );
      expect(find.textContaining('カメラを利用できません'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    for (final initialStart in [true, false]) {
      for (final coverRoute in [true, false]) {
        testWidgets(
          '$name stops a delayed ${initialStart ? 'initial' : 'retry'} start after ${coverRoute ? 'route cover' : 'backgrounding'}',
          (tester) async {
            camera.permissionGranted = initialStart;
            camera.startGate = Completer<void>();
            final navigator = await show(tester, page, settle: !initialStart);
            final controller = tester.widget<MobileScanner>(find.byType(MobileScanner)).controller!;
            if (!initialStart) {
              camera.permissionGranted = true;
              tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
              tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
              tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
              await tester.pump();
            }
            expect(controller.value.isStarting, isTrue);
            if (coverRoute) {
              navigator.currentState!.push(
                MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('cover'))),
              );
              await tester.pump();
            } else {
              tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
              tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
            }
            camera.startGate!.complete();
            await tester.pumpAndSettle();
            expect(controller.value.isRunning, isFalse);
            expect(camera.active, isFalse);
            expect(camera.stops, 1);
            if (coverRoute) {
              navigator.currentState!.pop();
            } else {
              tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
            }
            await tester.pumpAndSettle();
            expect(controller.value.isRunning, isTrue);
            expect(camera.active, isTrue);
            expect(camera.starts, initialStart ? 2 : 3);
            await tester.pumpWidget(const SizedBox());
            await tester.pump();
          },
        );
      }
    }

    testWidgets('$name handles a platform stop error and can resume later', (tester) async {
      await show(tester, page);
      camera.stopError = PlatformException(code: 'stop-failed');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(tester.takeException(), isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(camera.starts, 2);
      expect(camera.active, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('$name waits for camera shutdown before resuming', (tester) async {
      await show(tester, page);
      expect(camera.starts, 1);
      camera.stopGate = Completer<void>();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(camera.stops, 1);
      expect(camera.starts, 1);
      camera.stopGate!.complete();
      await tester.pumpAndSettle();
      expect(camera.starts, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('$name does not restart behind another route', (tester) async {
      final navigator = await show(tester, page);
      navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('cover'))));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(camera.starts, 1);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(camera.starts, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('$name tolerates permission prompt lifecycle changes during startup', (tester) async {
      camera.onStart = () {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      };
      await show(tester, page);
      expect(camera.starts, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('$name does not restart or consume another code after completing', (tester) async {
      final auth = FakeAuthRepository(initialUser: FakeUser(uid: 'attendee'));
      addTearDown(auth.dispose);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home')),
          ),
          GoRoute(path: '/scan', builder: (_, _) => page()),
          GoRoute(
            path: '/s/:token',
            builder: (_, _) => const Scaffold(body: Text('stamp result')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        TranslationProvider(
          child: ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(auth),
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
      await tester.pumpAndSettle();
      unawaited(router.push('/scan'));
      await tester.pumpAndSettle();
      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      final capture = BarcodeCapture(
        barcodes: [
          Barcode(rawValue: name == 'stamp rally' ? 'https://2026-app.flutterkaigi.jp/s/${'ab' * 32}' : '123456'),
        ],
      );
      scanner.onDetect!(capture);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      scanner.onDetect!(capture);
      scanner.onDetect!(capture);
      await tester.pumpAndSettle();
      expect(camera.starts, 1);
      expect(find.text(name == 'stamp rally' ? 'stamp result' : 'home'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('leaving $name scanner and opening it again after permission is granted recovers', (tester) async {
      camera.permissionGranted = false;
      final navigator = await show(tester, page);
      expect(camera.starts, 1);
      expect(find.textContaining('カメラを利用できません'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      camera.permissionGranted = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(camera.starts, 2);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => page()));
      await tester.pumpAndSettle();
      expect(camera.starts, 3);
      expect(find.textContaining('カメラを利用できません'), findsNothing);
      expect(find.byKey(const Key('camera-preview')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }
}

class _Camera extends MobileScannerPlatform {
  bool permissionGranted = true;
  int starts = 0;
  int stops = 0;
  Completer<void>? stopGate;
  Completer<void>? startGate;
  Completer<void>? permissionGate;
  PlatformException? stopError;
  bool active = false;
  VoidCallback? onStart;
  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();
  @override
  Stream<TorchState> get torchStateStream => Stream.value(TorchState.unavailable);
  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);
  @override
  Widget buildCameraView() => const SizedBox(key: Key('camera-preview'));
  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    starts++;
    onStart?.call();
    await permissionGate?.future;
    if (!permissionGranted) {
      throw const MobileScannerException(errorCode: MobileScannerErrorCode.permissionDenied);
    }
    await startGate?.future;
    active = true;
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(300, 500),
      numberOfCameras: 1,
    );
  }

  @override
  Future<void> stop() async {
    stops++;
    await stopGate?.future;
    final error = stopError;
    stopError = null;
    if (error != null) {
      throw error;
    }
    active = false;
  }

  @override
  Future<void> dispose() async {}
}
