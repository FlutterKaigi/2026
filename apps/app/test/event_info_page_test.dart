import 'package:app/core/constants/app_links.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/package_info.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/ui/widget/trademark_footer_widget.dart';
import 'package:app/feature/event/ui/page/event_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('venue map link contains the exact venue name and address', () {
    final query = Uri.parse(AppLinks.venueMap).queryParameters['query'];

    expect(query, '浜松町コンベンションホール 東京都港区浜松町二丁目3番1号');
  });

  testWidgets('shows the 2026 event overview on a compact screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpEventInfoPage(tester);

    expect(find.text('イベント概要'), findsOneWidget);
    expect(find.text('最新のお知らせ'), findsOneWidget);
    expect(find.text('会って、話して、熱くなる。'), findsOneWidget);
    expect(find.text('〜Assemble〜'), findsOneWidget);
    expect(find.text('2026年10月29日(木) – 30日(金)'), findsOneWidget);
    expect(find.text('浜松町コンベンションホール'), findsOneWidget);
    expect(find.text('地図を見る'), findsOneWidget);
    expect(
      tester.getSize(find.widgetWithText(TextButton, '地図を見る')).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.text('チケットを購入'), findsNothing);
    expect(
      find.bySemanticsLabel('FlutterKaigi 2026 ロゴ'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.text('その他'), 500);
    await tester.pumpAndSettle();

    expect(find.text('クレジット'), findsOneWidget);
    expect(find.text('コントリビューター'), findsOneWidget);
    expect(find.text('その他'), findsOneWidget);
    expect(
      tester
          .getSize(
            find.ancestor(
              of: find.text('公式Webサイト'),
              matching: find.byType(ListTile),
            ),
          )
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.text('アプリ設定'), findsNothing);
    expect(find.byType(TrademarkFooterWidget), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('opens news from the event overview banner', (tester) async {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    addTearDown(() => GoRouter.optionURLReflectsImperativeAPIs = false);
    final router = GoRouter(
      initialLocation: '/info',
      routes: [
        GoRoute(
          path: '/info',
          builder: (context, state) => const EventInfoPage(),
        ),
        GoRoute(
          path: '/news',
          builder: (context, state) => const Scaffold(
            body: Text('news destination'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpEventInfoPage(tester, router: router);
    await tester.tap(find.text('最新のお知らせ'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/news');
    expect(find.text('news destination'), findsOneWidget);
  });

  testWidgets('opens the contributor list from the event overview', (
    tester,
  ) async {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    addTearDown(() => GoRouter.optionURLReflectsImperativeAPIs = false);
    final router = GoRouter(
      initialLocation: '/info',
      routes: [
        GoRoute(
          path: '/info',
          builder: (context, state) => const EventInfoPage(),
        ),
        GoRoute(
          path: '/contributors',
          builder: (context, state) => const Scaffold(
            body: Text('contributor destination'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpEventInfoPage(tester, router: router);
    await tester.scrollUntilVisible(find.text('コントリビューター'), 200);
    await tester.ensureVisible(find.text('コントリビューター'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('コントリビューター'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/contributors');
    expect(find.text('contributor destination'), findsOneWidget);
  });

  testWidgets('opens the OSS license list from the event overview', (
    tester,
  ) async {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    addTearDown(() => GoRouter.optionURLReflectsImperativeAPIs = false);
    final router = GoRouter(
      initialLocation: '/info',
      routes: [
        GoRoute(
          path: '/info',
          builder: (context, state) => const EventInfoPage(),
        ),
        GoRoute(
          path: '/licenses',
          builder: (context, state) => const Scaffold(
            body: Text('license destination'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpEventInfoPage(tester, router: router);
    await tester.scrollUntilVisible(find.text('OSSライセンス'), 200);
    await tester.ensureVisible(find.text('OSSライセンス'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OSSライセンス'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/licenses');
    expect(find.text('license destination'), findsOneWidget);
  });
}

Future<void> _pumpEventInfoPage(
  WidgetTester tester, {
  GoRouter? router,
}) async {
  SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          packageInfoProvider.overrideWithValue(
            AsyncData(
              PackageInfo(
                appName: 'FlutterKaigi 2026',
                packageName: 'jp.flutterkaigi.conf2026',
                version: '1.2.3',
                buildNumber: '45',
              ),
            ),
          ),
        ],
        child: router == null
            ? MaterialApp(
                locale: const Locale('ja'),
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: const EventInfoPage(),
              )
            : MaterialApp.router(
                routerConfig: router,
                locale: const Locale('ja'),
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
              ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
