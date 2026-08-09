import 'package:app/core/constants/app_links.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/package_info.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/ui/launch_external_url.dart';
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

  testWidgets('opens Japanese docs links when Japanese is selected', (
    tester,
  ) async {
    _useCompactViewport(tester);
    final openedUris = <Uri>[];

    await _pumpEventInfoPage(
      tester,
      externalUrlLauncher: (uri) async {
        openedUris.add(uri);
        return true;
      },
    );

    await _tapDocsLinks(tester, locale: AppLocale.ja);

    expect(openedUris, [
      Uri.parse(AppLinks.codeOfConductJa),
      Uri.parse(AppLinks.privacyPolicyJa),
      Uri.parse(AppLinks.exclusionPolicyJa),
    ]);
  });

  testWidgets('opens English docs links when English is selected', (
    tester,
  ) async {
    _useCompactViewport(tester);
    final openedUris = <Uri>[];

    await _pumpEventInfoPage(
      tester,
      locale: AppLocale.en,
      externalUrlLauncher: (uri) async {
        openedUris.add(uri);
        return true;
      },
    );

    await _tapDocsLinks(tester, locale: AppLocale.en);

    expect(openedUris, [
      Uri.parse(AppLinks.codeOfConductEn),
      Uri.parse(AppLinks.privacyPolicyEn),
      Uri.parse(AppLinks.exclusionPolicyEn),
    ]);
  });
}

void _useCompactViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpEventInfoPage(
  WidgetTester tester, {
  GoRouter? router,
  AppLocale locale = AppLocale.ja,
  ExternalUrlLauncher? externalUrlLauncher,
}) async {
  await LocaleSettings.setLocale(locale);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.ja));
  SharedPreferences.setMockInitialValues({'app_locale': locale.languageCode});
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
                locale: locale.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: EventInfoPage(externalUrlLauncher: externalUrlLauncher),
              )
            : MaterialApp.router(
                routerConfig: router,
                locale: locale.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
              ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapDocsLinks(
  WidgetTester tester, {
  required AppLocale locale,
}) async {
  final labels = switch (locale) {
    AppLocale.ja => [
      '行動規範',
      'プライバシーポリシー',
      '反社会的勢力排除に関する基本方針',
    ],
    AppLocale.en => [
      'Code of Conduct',
      'Privacy Policy',
      'Exclusion of Anti-Social Forces',
    ],
  };

  for (final label in labels) {
    final tile = find.ancestor(
      of: find.text(label),
      matching: find.byType(ListTile),
    );
    await tester.scrollUntilVisible(tile, 500);
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pump();
  }
}
