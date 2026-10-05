import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/environment.dart';
import 'package:app/feature/support_lt/ui/page/support_lt_scan_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'fake_mobile_scanner_platform.dart';

const _invalidMessage = '読み取れませんでした。応援LT参加登録用のQRコードか確認してください';

void main() {
  final originalPlatform = MobileScannerPlatform.instance;
  setUpAll(() => MobileScannerPlatform.instance = FakeMobileScannerPlatform());
  tearDownAll(() => MobileScannerPlatform.instance = originalPlatform);

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  /// Opens the scanner the way the registration page does and records what it
  /// pops with.
  Future<List<String?>> openScanPage(WidgetTester tester, {Flavor flavor = Flavor.production}) async {
    final results = <String?>[];
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            environmentProvider.overrideWithValue(Environment.fromEnvironment().copyWith(flavor: flavor)),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () async => results.add(
                      await Navigator.of(context).push<String>(
                        MaterialPageRoute(builder: (_) => const SupportLtScanPage()),
                      ),
                    ),
                    child: const Text('open scan'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open scan'));
    await tester.pumpAndSettle();
    return results;
  }

  void detect(WidgetTester tester, String rawValue) {
    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    scanner.onDetect!(BarcodeCapture(barcodes: [Barcode(rawValue: rawValue)]));
  }

  for (final scenario in [
    (flavor: Flavor.production, accepted: productionAppOrigin, rejected: stagingAppOrigin),
    (flavor: Flavor.staging, accepted: stagingAppOrigin, rejected: productionAppOrigin),
  ]) {
    testWidgets("${scenario.flavor.shortName} scanning returns the code from its own backend's link only", (
      tester,
    ) async {
      final results = await openScanPage(tester, flavor: scenario.flavor);

      detect(tester, supportLtQrPayload('123456', origin: scenario.rejected));
      await tester.pumpAndSettle();
      expect(find.text(_invalidMessage), findsOneWidget);
      expect(find.byType(SupportLtScanPage), findsOneWidget);
      expect(results, isEmpty);

      detect(tester, supportLtQrPayload('123456', origin: scenario.accepted));
      await tester.pumpAndSettle();
      expect(find.byType(SupportLtScanPage), findsNothing);
      expect(results, ['123456']);
    });
  }

  testWidgets('develop scanning returns a bare code and rejects links to live apps', (tester) async {
    final results = await openScanPage(tester, flavor: Flavor.develop);

    for (final origin in [productionAppOrigin, stagingAppOrigin]) {
      detect(tester, supportLtQrPayload('123456', origin: origin));
      await tester.pumpAndSettle();
      expect(find.byType(SupportLtScanPage), findsOneWidget);
    }
    expect(results, isEmpty);

    detect(tester, supportLtQrPayload('123456', origin: null));
    await tester.pumpAndSettle();
    expect(results, ['123456']);
  });

  testWidgets('keeps scanning after a QR code for another feature', (tester) async {
    final results = await openScanPage(tester);

    detect(tester, '$productionAppOrigin/x/v1.other-uid.9999999999.deadbeef');
    await tester.pumpAndSettle();

    expect(find.text(_invalidMessage), findsOneWidget);
    expect(find.byType(SupportLtScanPage), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('pops once when the camera reports the same QR code repeatedly', (tester) async {
    final results = await openScanPage(tester);

    for (var detection = 0; detection < 3; detection++) {
      detect(tester, supportLtQrPayload('123456', origin: productionAppOrigin));
    }
    await tester.pumpAndSettle();

    expect(results, ['123456']);
    expect(find.text('open scan'), findsOneWidget);
  });

  testWidgets('explains the code entry fallback when the camera is unavailable', (tester) async {
    await openScanPage(tester);

    expect(find.text('カメラを利用できません。設定でカメラへのアクセスを許可するか、前の画面で6桁のコードを入力してください'), findsOneWidget);
  });
}
