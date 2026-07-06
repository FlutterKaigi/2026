import 'package:app/core/provider/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Reads and persists the user's preferred [ThemeMode] in local storage.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _prefsKey = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(_prefsKey);
    return ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
  }

  /// Updates the active [ThemeMode] and persists the choice.
  Future<void> set(ThemeMode mode) async {
    await ref.read(sharedPreferencesProvider).setString(_prefsKey, mode.name);
    state = mode;
  }
}

/// Exposes the persisted [ThemeMode] and a setter to change it.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
