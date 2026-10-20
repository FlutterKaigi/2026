import 'package:flutter/material.dart';

/// 会場の投影画面だけで使うダークの配色。
///
/// 参加者アプリのダーク配色（apps/app の `darkColorScheme`）と同じ値にそろえる。
/// ダッシュボードのほかの画面のテーマは変えない。
const quizProjectionColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFCFBDFE),
  onPrimary: Color(0xFF36275D),
  primaryContainer: Color(0xFF4D3D75),
  onPrimaryContainer: Color(0xFFE9DDFF),
  primaryFixed: Color(0xFFE9DDFF),
  primaryFixedDim: Color(0xFFCFBDFE),
  onPrimaryFixed: Color(0xFF201047),
  onPrimaryFixedVariant: Color(0xFF4D3D75),
  secondary: Color(0xFFFFB3AC),
  onSecondary: Color(0xFF571E1A),
  secondaryContainer: Color(0xFF73332F),
  onSecondaryContainer: Color(0xFFFFDAD6),
  secondaryFixed: Color(0xFFFFDAD6),
  secondaryFixedDim: Color(0xFFFFB3AC),
  onSecondaryFixed: Color(0xFF3B0908),
  onSecondaryFixedVariant: Color(0xFF73332F),
  tertiary: Color(0xFFA6C8FF),
  onTertiary: Color(0xFF01315E),
  tertiaryContainer: Color(0xFF224876),
  onTertiaryContainer: Color(0xFFD4E3FF),
  tertiaryFixed: Color(0xFFD4E3FF),
  tertiaryFixedDim: Color(0xFFA6C8FF),
  onTertiaryFixed: Color(0xFF001C3A),
  onTertiaryFixedVariant: Color(0xFF224876),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF141218),
  onSurface: Color(0xFFE6E0E9),
  onSurfaceVariant: Color(0xFFCAC4CF),
  surfaceDim: Color(0xFF141218),
  surfaceBright: Color(0xFF3B383E),
  surfaceContainerLowest: Color(0xFF0F0D13),
  surfaceContainerLow: Color(0xFF1D1B20),
  surfaceContainer: Color(0xFF211F24),
  surfaceContainerHigh: Color(0xFF2B292F),
  surfaceContainerHighest: Color(0xFF36343A),
  outline: Color(0xFF948F99),
  outlineVariant: Color(0xFF49454E),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE6E0E9),
  onInverseSurface: Color(0xFF322F35),
  inversePrimary: Color(0xFF65558F),
  surfaceTint: Color(0xFFCFBDFE),
);

/// 投影画面のテーマ。
final quizProjectionTheme = ThemeData(colorScheme: quizProjectionColorScheme);

/// FlutterKaigi のブランドのグラデーション（参加者アプリの `AppGradients.brand` と同じ値）。
const quizProjectionBrandGradient = LinearGradient(
  colors: [
    Color(0xFFFF0055),
    Color(0xFF6200EA),
    Color(0xFF6200EA),
    Color(0xFF001155),
  ],
  stops: [0, 0.4, 0.6, 1],
);
