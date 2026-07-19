/// Generates `apps/website/lib/constants/generated_tokens.dart` from the
/// W3C-flavored JSON exported under `docs/design-system/tokens/`.
///
/// Run via:
///
/// ```sh
/// fvm dart run melos tokens:generate
/// ```
///
/// or directly:
///
/// ```sh
/// fvm dart run tool/generate_tokens.dart
/// ```
///
/// The generated file is checked into git; re-run this script whenever the
/// tokens are updated.
library;

import 'dart:convert';
import 'dart:io';

const _tokensDir = 'docs/design-system/tokens';
const _outFile = 'apps/website/lib/constants/generated_tokens.dart';

void main(List<String> args) {
  final colors = _readJson('color.tokens.json');
  final fonts = _readJson('font.tokens.json');
  final effects = _readJson('effect.tokens.json');

  final out = StringBuffer()
    ..writeln('// GENERATED FILE — do not edit by hand.')
    ..writeln('// Source of truth: $_tokensDir/')
    ..writeln('// Regenerate via: fvm dart run melos tokens:generate')
    ..writeln('// ignore_for_file: constant_identifier_names, lines_longer_than_80_chars')
    ..writeln()
    ..writeln("import 'package:jaspr/dom.dart';")
    ..writeln()
    ..write(_typeDecls)
    ..writeln();

  // ── Colors ────────────────────────────────────────────────────────
  out.writeln('// ── Colors ($_tokensDir/color.tokens.json) ──');
  _walk(colors, const [], (path, leaf) {
    if (leaf['type'] != 'color') return;
    final hex = _normalizeHex(leaf['value'] as String);
    final name = _camel(path);
    out
      ..writeln('const $name = Color(\'$hex\');')
      ..writeln('const ${name}Hex = \'$hex\';');
  });
  out.writeln();

  // ── Font styles ───────────────────────────────────────────────────
  out.writeln('// ── Font styles ($_tokensDir/font.tokens.json) ──');
  _walk(fonts, const [], (path, leaf) {
    if (leaf['type'] != 'custom-fontStyle') return;
    final v = leaf['value'] as Map<String, dynamic>;
    final name = _camel(path);
    out
      ..writeln('const $name = TokenFontStyle(')
      ..writeln("  fontFamily: '${v['fontFamily']}',")
      ..writeln('  fontSize: ${v['fontSize']},')
      ..writeln('  fontWeight: ${v['fontWeight']},')
      ..writeln('  lineHeight: ${v['lineHeight']},')
      ..writeln('  letterSpacing: ${v['letterSpacing']},')
      ..writeln(');');
  });
  out.writeln();

  // ── Effects ───────────────────────────────────────────────────────
  out.writeln('// ── Effects ($_tokensDir/effect.tokens.json) ──');
  _walk(effects, const [], (path, leaf) {
    if (leaf['type'] != 'custom-shadow') return;
    final v = leaf['value'] as Map<String, dynamic>;
    final name = _camel(path);
    out
      ..writeln('const $name = TokenShadow(')
      ..writeln("  shadowType: '${v['shadowType']}',")
      ..writeln("  color: '${_normalizeHex(v['color'] as String)}',")
      ..writeln('  offsetX: ${v['offsetX']},')
      ..writeln('  offsetY: ${v['offsetY']},')
      ..writeln('  radius: ${v['radius']},')
      ..writeln('  spread: ${v['spread']},')
      ..writeln(');');
  });

  File(_outFile).writeAsStringSync(out.toString());

  // Format the generated file so it stays diff-friendly.
  final fmt = Process.runSync('fvm', ['dart', 'format', _outFile]);
  if (fmt.exitCode != 0) {
    stderr.writeln('warning: dart format exited with ${fmt.exitCode}');
    stderr.writeln(fmt.stderr);
  }

  stdout.writeln('Wrote $_outFile');
}

const _typeDecls = r'''
/// Wrapper for a `custom-fontStyle` token.
class TokenFontStyle {
  const TokenFontStyle({
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.lineHeight,
    required this.letterSpacing,
  });

  final String fontFamily;
  final num fontSize;
  final int fontWeight;
  final num lineHeight;
  final num letterSpacing;
}

/// Wrapper for a `custom-shadow` token.
class TokenShadow {
  const TokenShadow({
    required this.shadowType,
    required this.color,
    required this.offsetX,
    required this.offsetY,
    required this.radius,
    required this.spread,
  });

  final String shadowType;
  final String color;
  final num offsetX;
  final num offsetY;
  final num radius;
  final num spread;

  /// Renders this shadow as a CSS `box-shadow` value.
  String get cssBoxShadow =>
      '${offsetX}px ${offsetY}px ${radius}px ${spread}px $color';

  /// Renders this shadow as a CSS `filter: drop-shadow()` value.
  String get cssDropShadow =>
      'drop-shadow(${offsetX}px ${offsetY}px ${radius}px $color)';
}
''';

Map<String, dynamic> _readJson(String filename) {
  final raw = File('$_tokensDir/$filename').readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

void _walk(
  Map<String, dynamic> node,
  List<String> path,
  void Function(List<String> path, Map<String, dynamic> leaf) emit,
) {
  for (final entry in node.entries) {
    final value = entry.value;
    if (value is! Map<String, dynamic>) continue;
    if (value.containsKey('type') && value.containsKey('value')) {
      emit([...path, entry.key], value);
    } else {
      _walk(value, [...path, entry.key], emit);
    }
  }
}

/// `['color', 'deeppurple', 'sys', 'light-high-contrast', 'on-primary']`
/// → `colorDeeppurpleSysLightHighContrastOnPrimary`
///
/// Non-alphanumeric characters (including `.`, `/`, `-`, `_`, whitespace)
/// are treated as word separators. A leading digit gets prefixed with `t`
/// since Dart identifiers cannot start with a digit.
String _camel(List<String> path) {
  final words = <String>[];
  for (final segment in path) {
    for (final w in segment.split(RegExp(r'[^a-zA-Z0-9]+'))) {
      if (w.isNotEmpty) words.add(w);
    }
  }
  if (words.isEmpty) return '_';
  final buf = StringBuffer(words.first.toLowerCase());
  for (final w in words.skip(1)) {
    buf
      ..write(w[0].toUpperCase())
      ..write(w.substring(1).toLowerCase());
  }
  final name = buf.toString();
  return RegExp(r'^[0-9]').hasMatch(name) ? 't$name' : name;
}

/// Normalize a hex color:
///   - Lowercase input → uppercase output.
///   - Strip the alpha byte when fully opaque (`...FF` → 6-digit form).
String _normalizeHex(String input) {
  var v = input.trim();
  if (!v.startsWith('#')) return v;
  v = '#${v.substring(1).toUpperCase()}';
  if (v.length == 9 && v.endsWith('FF')) {
    return v.substring(0, 7);
  }
  return v;
}
