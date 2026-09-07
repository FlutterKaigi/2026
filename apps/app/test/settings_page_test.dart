import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/package_info.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/provider/theme_mode.dart';
import 'package:app/feature/settings/ui/page/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows theme, language, and app information', (tester) async {
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
          child: MaterialApp(
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const SettingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('設定'), findsOneWidget);
    expect(find.text('表示設定'), findsOneWidget);
    expect(find.text('テーマ'), findsOneWidget);
    expect(find.text('表示言語'), findsOneWidget);
    expect(find.text('システムに合わせる'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);
    expect(find.text('アプリ情報'), findsOneWidget);
    expect(find.text('1.2.3 (45)'), findsOneWidget);
    expect(find.byType(RadioGroup<ThemeMode>), findsOneWidget);
    expect(find.byType(RadioGroup<AppLocale>), findsOneWidget);
    expect(find.byType(RadioListTile<ThemeMode>), findsNWidgets(3));
    expect(find.byType(RadioListTile<AppLocale>), findsNWidgets(2));
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      tester
          .getSize(
            find.ancestor(
              of: find.text('システムに合わせる'),
              matching: find.byType(RadioListTile<ThemeMode>),
            ),
          )
          .height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.text('ダーク'));
    await tester.pumpAndSettle();
    expect(preferences.getString('theme_mode'), 'dark');

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(preferences.getString('app_locale'), 'en');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('shows a message when saving a setting fails', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            themeModeProvider.overrideWith(_FailingThemeModeNotifier.new),
            packageInfoProvider.overrideWithValue(
              const AsyncValue.loading(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const SettingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ダーク'));
    await tester.pump();

    expect(find.text('設定を保存できませんでした'), findsOneWidget);
  });

  testWidgets('returns to the event overview from a direct settings URL', (
    tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final preferences = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/info',
          builder: (_, _) => const Scaffold(body: Text('event destination')),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => const SettingsPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            packageInfoProvider.overrideWithValue(
              const AsyncValue.loading(),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('戻る'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/info');
    expect(find.text('event destination'), findsOneWidget);
  });
}

class _FailingThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.system;

  @override
  Future<void> set(ThemeMode mode) async {
    throw StateError('storage failure');
  }
}
