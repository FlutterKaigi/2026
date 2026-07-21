import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_locale';

/// Initializes localization from persisted user preference or system locale.
///
/// The first launch follows the system locale when it is supported. Unsupported
/// system locales fall back to English, and the resolved locale is persisted so
/// future launches keep using the same language.
Future<AppLocale> initializeAppLocale(SharedPreferences prefs) async {
  final locale =
      readStoredAppLocale(prefs) ??
      resolvePreferredAppLocale(
        WidgetsBinding.instance.platformDispatcher.locales,
      );
  await LocaleSettings.setLocale(locale);
  await prefs.setString(_prefsKey, locale.languageCode);
  return locale;
}

/// Resolves the best supported app locale from platform locale preferences.
AppLocale resolvePreferredAppLocale(Iterable<Locale> preferredLocales) {
  for (final locale in preferredLocales) {
    final appLocale = appLocaleFromLanguageCode(locale.languageCode);
    if (appLocale != null) {
      return appLocale;
    }
  }
  return AppLocale.en;
}

/// Reads a previously persisted app locale.
AppLocale? readStoredAppLocale(SharedPreferences prefs) {
  return appLocaleFromLanguageCode(prefs.getString(_prefsKey));
}

/// Converts a supported language code to [AppLocale].
AppLocale? appLocaleFromLanguageCode(String? languageCode) {
  if (languageCode == null) {
    return null;
  }

  for (final locale in AppLocale.values) {
    if (locale.languageCode == languageCode) {
      return locale;
    }
  }
  return null;
}

/// Reads and persists the user's preferred app locale.
class AppLocaleNotifier extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return readStoredAppLocale(prefs) ?? LocaleSettings.currentLocale;
  }

  /// Updates the active locale and persists the choice.
  Future<void> set(AppLocale locale) async {
    await LocaleSettings.setLocale(locale);
    await ref
        .read(sharedPreferencesProvider)
        .setString(
          _prefsKey,
          locale.languageCode,
        );
    state = locale;
  }
}

/// Exposes the persisted app locale and a setter to change it.
final appLocaleProvider = NotifierProvider<AppLocaleNotifier, AppLocale>(
  AppLocaleNotifier.new,
);
