import 'package:app/core/designsystem/theme/color_scheme.dart';
import 'package:flutter/material.dart';

/// Builds the light [ThemeData] for the app.
ThemeData lightTheme() => _themeFrom(lightColorScheme);

/// Builds the dark [ThemeData] for the app.
ThemeData darkTheme() => _themeFrom(darkColorScheme);

/// UI font family from the design system: Noto Sans JP for all UI text.
const _fontFamily = 'Noto Sans JP';

/// Background color shared by the app bottom navigation and Android system nav.
Color appNavigationBarColor(ColorScheme colorScheme) => colorScheme.surfaceContainer;

ThemeData _themeFrom(ColorScheme colorScheme) => ThemeData(
  colorScheme: colorScheme,
  fontFamily: _fontFamily,
  appBarTheme: const AppBarTheme(centerTitle: false),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: appNavigationBarColor(colorScheme),
  ),
);
