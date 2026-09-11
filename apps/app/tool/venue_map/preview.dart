// Isolated preview of the production page, without Firebase initialization.
// fvm flutter run -d web-server -t tool/venue_map/preview.dart --web-port 8766
import 'package:app/core/designsystem/theme/app_theme.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/app_locale.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/provider/theme_mode.dart';
import 'package:app/feature/settings/ui/page/settings_page.dart';
import 'package:app/feature/venue_map/ui/page/venue_map_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep Flutter controls available to browser accessibility inspection in this preview.
  WidgetsBinding.instance.ensureSemantics();
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
  final locale =
      appLocaleFromLanguageCode(Uri.base.queryParameters['locale']) ?? readStoredAppLocale(preferences) ?? AppLocale.ja;
  await container.read(appLocaleProvider.notifier).set(locale);
  final requestedTheme = ThemeMode.values.asNameMap()[Uri.base.queryParameters['theme']];
  if (requestedTheme != null) {
    await container.read(themeModeProvider.notifier).set(requestedTheme);
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(child: const _Preview()),
    ),
  );
}

class _Preview extends ConsumerStatefulWidget {
  const _Preview();
  @override
  ConsumerState<_Preview> createState() => _PreviewState();
}

class _PreviewState extends ConsumerState<_Preview> {
  late final _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const VenueMapPage()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: lightTheme(),
    darkTheme: darkTheme(),
    themeMode: ref.watch(themeModeProvider),
    locale: TranslationProvider.of(context).flutterLocale,
    supportedLocales: AppLocaleUtils.supportedLocales,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: _router,
  );
}
