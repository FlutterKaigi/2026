// Isolated preview of the production page, without Firebase initialization.
// fvm flutter run -d web-server -t tool/venue_map/preview.dart --web-port 8766
import 'package:app/core/designsystem/theme/app_theme.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/venue_map/ui/page/venue_map_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep Flutter controls available to browser accessibility inspection in this preview.
  WidgetsBinding.instance.ensureSemantics();
  final preferences = await SharedPreferences.getInstance();
  await LocaleSettings.setLocale(Uri.base.queryParameters['locale'] == 'en' ? AppLocale.en : AppLocale.ja);
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: TranslationProvider(child: const _Preview()),
    ),
  );
}

class _Preview extends StatelessWidget {
  const _Preview();
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: lightTheme(),
    darkTheme: darkTheme(),
    themeMode: Uri.base.queryParameters['theme'] == 'dark' ? ThemeMode.dark : ThemeMode.light,
    locale: TranslationProvider.of(context).flutterLocale,
    supportedLocales: AppLocaleUtils.supportedLocales,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const VenueMapPage(),
  );
}
