import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/app_locale.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolvePreferredAppLocale', () {
    test('uses the first supported locale from platform preferences', () {
      final locale = resolvePreferredAppLocale([
        const Locale('fr'),
        const Locale('ja'),
        const Locale('en'),
      ]);

      expect(locale, AppLocale.ja);
    });

    test('falls back to English when platform locales are unsupported', () {
      final locale = resolvePreferredAppLocale([
        const Locale('fr'),
        const Locale('de'),
      ]);

      expect(locale, AppLocale.en);
    });
  });
}
