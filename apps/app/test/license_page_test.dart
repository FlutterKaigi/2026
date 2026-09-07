import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/license/data/license_provider.dart';
import 'package:app/feature/license/ui/page/license_detail_page.dart';
import 'package:app/feature/license/ui/page/license_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('lists and filters bundled package licenses', (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            licensesProvider.overrideWithValue(
              const AsyncData({
                'example_package': [
                  [LicenseParagraph('Example license', 0)],
                ],
              }),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const OssLicensePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ライセンス'), findsOneWidget);
    expect(find.text('パッケージを検索'), findsOneWidget);
    expect(find.text('example_package'), findsOneWidget);
    expect(find.text('ライセンス: 1件'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), 'missing');
    await tester.pump();
    expect(find.text('example_package'), findsNothing);
  });

  test('uses the correct English singular license count', () async {
    final translations = await AppLocale.en.build();

    expect(translations.licenses.licenseCount(n: 1), '1 license');
    expect(translations.licenses.licenseCount(n: 2), '2 licenses');
  });

  testWidgets('renders license details and the missing package state', (
    tester,
  ) async {
    await _pumpLicenseWidget(
      tester,
      locale: const Locale('ja'),
      child: const LicenseDetailPage(packageName: 'example_package'),
    );

    expect(find.text('Example license'), findsOneWidget);

    await _pumpLicenseWidget(
      tester,
      locale: const Locale('ja'),
      child: const LicenseDetailPage(packageName: 'missing_package'),
    );

    expect(find.text('ライセンスが見つかりませんでした'), findsOneWidget);
  });

  testWidgets('returns to the event overview from a direct license URL', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/licenses',
      routes: [
        GoRoute(
          path: '/info',
          builder: (_, _) => const Scaffold(body: Text('event destination')),
        ),
        GoRoute(
          path: '/licenses',
          builder: (_, _) => const OssLicensePage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpLicenseWidget(
      tester,
      locale: const Locale('ja'),
      router: router,
    );
    await tester.tap(find.byTooltip('戻る'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/info');
    expect(find.text('event destination'), findsOneWidget);
  });
}

const _licenses = {
  'example_package': [
    [LicenseParagraph('Example license', 0)],
  ],
};

Future<void> _pumpLicenseWidget(
  WidgetTester tester, {
  required Locale locale,
  Widget? child,
  GoRouter? router,
}) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          licensesProvider.overrideWithValue(const AsyncData(_licenses)),
        ],
        child: router == null
            ? MaterialApp(
                locale: locale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: child,
              )
            : MaterialApp.router(
                routerConfig: router,
                locale: locale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
              ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
