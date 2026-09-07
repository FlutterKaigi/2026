import 'package:country_flags/country_flags.dart' as country_flags;
import 'package:data/data.dart';
import 'package:flutter/material.dart';

/// Renders a country's flag as a small rounded SVG (flag-icons via the
/// `country_flags` package).
///
/// Emoji flags were the first choice, but Flutter on iOS does not shape the
/// regional indicator pair into a flag when the app's font family (Noto Sans
/// JP) lacks the glyphs, so the picker showed two missing-glyph boxes. Bundled
/// SVGs also render identically on every platform.
class CountryFlagIcon extends StatelessWidget {
  const CountryFlagIcon({required this.country, this.height = 20, super.key});

  final Country country;

  /// Flag height; the width keeps the 4:3 ratio of the flag-icons assets.
  final double height;

  @override
  Widget build(BuildContext context) {
    final width = height * 4 / 3;
    return Semantics(
      label: country.code,
      child: SizedBox(
        width: width,
        height: height,
        child: country_flags.CountryFlag.fromCountryCode(
          country.code,
          theme: country_flags.ImageTheme(
            width: width,
            height: height,
            shape: const country_flags.RoundedRectangle(3),
          ),
        ),
      ),
    );
  }
}
