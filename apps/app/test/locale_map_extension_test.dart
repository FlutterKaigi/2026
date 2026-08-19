import 'package:app/core/extension/locale_map_extension.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocaleMapX.resolve', () {
    test('returns the requested locale when it has a value', () {
      const value = LocaleMap(ja: '日本語', en: 'English');

      expect(value.resolve(const Locale('ja')), '日本語');
      expect(value.resolve(const Locale('en')), 'English');
    });

    test('falls back to English when Japanese is empty', () {
      const value = LocaleMap(ja: '', en: 'English');

      expect(value.resolve(const Locale('ja')), 'English');
    });

    test('falls back to Japanese when English is empty', () {
      const value = LocaleMap(ja: '日本語', en: '');

      expect(value.resolve(const Locale('en')), '日本語');
    });

    test('treats whitespace-only values as empty', () {
      const value = LocaleMap(ja: '  ', en: 'English');

      expect(value.resolve(const Locale('ja')), 'English');
    });

    test('returns an empty string when both locales are empty', () {
      const value = LocaleMap(ja: ' ', en: '\n');

      expect(value.resolve(const Locale('ja')), isEmpty);
      expect(value.resolve(const Locale('en')), isEmpty);
    });

    test('uses English as the primary locale for unsupported locales', () {
      const value = LocaleMap(ja: '日本語', en: 'English');

      expect(value.resolve(const Locale('fr')), 'English');
    });
  });
}
