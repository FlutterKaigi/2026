import 'package:jaspr/dom.dart';

import 'generated_tokens.dart';

// Project-friendly aliases over `generated_tokens.dart`. The generated file is
// the source of truth (regenerate via `melos run tokens:generate`); this file
// only picks the tokens the website currently uses and gives them shorter
// names.

// ── Brand (key) colors ────────────────────────────────────────────────
/// Brand gradient — start (Magenta Red).
const magentaRed = colorKeycolorsMagentared;

/// Brand symbol color (Deep Purple).
const deepPurple = colorKeycolorsPrimary;

/// Brand gradient — end (Deep Navy).
const deepNavy = colorKeycolorsDeepnavy;

// ── On-brand foreground variants for content over the gradient ────────
/// Pure white for content over the brand gradient.
const onBrand = Color('#FFFFFF');

/// 85% white — secondary copy over the gradient.
const onBrandMuted = Color('#FFFFFFD9');

/// 40% white — separators / inactive items over the gradient.
const onBrandSubtle = Color('#FFFFFF66');

// ── M3 light-surface palette (used by the white header) ───────────────
const surface = colorDeeppurpleSysLightSurface;
const onSurface = colorDeeppurpleSysLightOnSurface;
const onSurfaceVariant = colorDeeppurpleSysLightOnSurfaceVariant;
const outlineColor = colorDeeppurpleSysLightOutline;

// ── M3 light-surface content roles (used by event-section cards) ──────
const primary = colorDeeppurpleSysLightPrimary;
const primaryContainer = colorDeeppurpleSysLightPrimaryContainer;
const onPrimaryContainer = colorDeeppurpleSysLightOnPrimaryContainer;
const secondary = colorDeeppurpleSysLightSecondary;
const secondaryContainer = colorDeeppurpleSysLightSecondaryContainer;
const onSecondaryContainer = colorDeeppurpleSysLightOnSecondaryContainer;
const tertiaryContainer = colorDeeppurpleSysLightTertiaryContainer;

// ── M3 state-layer overlays (Hover 8% / Focus 10% / Pressed 16%) ──────
const onSecondaryContainerHover = colorDeeppurpleStateLayersLightOnsecondarycontainerOpacity010;
const onPrimaryContainerHoverHex = colorDeeppurpleStateLayersLightOnprimarycontainerOpacity008Hex;

// ── Event section brand accents (Figma-derived, no M3 semantic match) ──
// Bento Grid のカード階層やインパクト演出のため Figma で個別に選定された
// ブランド拡張色。生成トークン側にロールが無いため、ここで名前を付けて
// 一元管理する（将来 `color.tokens.json` 側で定義され直す可能性あり）。
const eventCardSurfaceInfo = Color('#EDE5F5');
const eventCardSurfaceRoadmap = Color('#F3EBFB');
const eventCardSurfaceSocial = Color('#F8F1FF');

const eventCardBorder = Color('#CBC3D94D'); // 30% — Info / Roadmap
const eventCardBorderSocial = Color('#CBC3D933'); // 20% — Social
const eventCardBorderNews = Color('#D9C3C94D'); // News

const eventRoadmapTimeline = Color('#CBC3D980'); // 50% タイムライン縦線
const eventRoadmapEmphasis = Color('#21005D'); // Conference 強調の名前色

// TODO(design): `#FFB4AB` は M3 ダークモードの Error と同値。
// 「ライト面の coral accent」として意図して選定されたかをデザイナーに確認。
const eventNewsIconBg = Color('#FFB4AB');

// Disabled CTA：M3 State Layer (8/10/16%) に該当する非活性塗りロールが無いため
// primary を 40% / onPrimary(白) を 90% に透過したカスタム値で表現している。
const eventCtaDisabledBg = Color('#65558F66');
const eventCtaDisabledFg = Color('#FFFFFFE6');

// ── Hero gradient ─────────────────────────────────────────────────────
/// CSS `background` value for the hero. Built from brand-color hex tokens so
/// it stays in sync with the design tokens.
const heroGradient =
    'linear-gradient(135deg, $colorKeycolorsMagentaredHex 0%, '
    '$colorKeycolorsPrimaryHex 55%, $colorKeycolorsDeepnavyHex 100%)';

// ── Typography stacks ─────────────────────────────────────────────────
/// Sans-serif stack for the product UI (Noto Sans JP).
const uiFontFamily = FontFamily.list([
  FontFamily('Noto Sans JP'),
  FontFamilies.sansSerif,
]);

/// Display stack for graphic / OGP-style copy (Poppins + Noto Sans JP fallback).
const displayFontFamily = FontFamily.list([
  FontFamily('Poppins'),
  FontFamily('Noto Sans JP'),
  FontFamilies.sansSerif,
]);

// ── Token helpers ─────────────────────────────────────────────────────

/// Map a numeric weight (100–900) from a token into a Jaspr [FontWeight].
FontWeight tokenWeight(int weight) => switch (weight) {
  100 => FontWeight.w100,
  200 => FontWeight.w200,
  300 => FontWeight.w300,
  400 => FontWeight.w400,
  500 => FontWeight.w500,
  600 => FontWeight.w600,
  700 => FontWeight.w700,
  800 => FontWeight.w800,
  900 => FontWeight.w900,
  _ => FontWeight.w400,
};

/// Build a `raw:` style map from a [TokenFontStyle].
///
/// Pass [fluidMin] and [fluidVw] (CSS-valid strings, e.g. `'2.25rem'`,
/// `'8vw'`) to wrap `font-size` in a `clamp()` whose upper bound is the
/// token's pixel size — this is how an OGP-scale token becomes the
/// max-bound for fluid web typography.
Map<String, String> tokenFontCss(
  TokenFontStyle t, {
  String? fluidMin,
  String? fluidVw,
}) {
  final maxPx = '${t.fontSize}px';
  final size = (fluidMin != null && fluidVw != null) ? 'clamp($fluidMin, $fluidVw, $maxPx)' : maxPx;
  final ratio = t.lineHeight / t.fontSize;
  return {
    'font-size': size,
    'line-height': ratio.toStringAsFixed(3),
    if (t.letterSpacing != 0) 'letter-spacing': '${t.letterSpacing}px',
  };
}
