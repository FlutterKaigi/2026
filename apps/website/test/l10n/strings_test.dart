import 'package:test/test.dart';
import 'package:website/l10n/strings.dart';

void main() {
  group('AppLocale.shareLinkFallbackRoutePath', () {
    test('is /x for the ja (root) locale', () {
      expect(AppLocale.ja.shareLinkFallbackRoutePath, '/x');
    });

    test('is /en/x for the en locale', () {
      expect(AppLocale.en.shareLinkFallbackRoutePath, '/en/x');
    });
  });

  group('Strings store badge labels', () {
    test('are localized for ja', () {
      final strings = Strings(AppLocale.ja);
      expect(strings.shareLinkPageGetIos, 'App Store からダウンロード');
      expect(strings.shareLinkPageGetAndroid, 'Google Play で手に入れよう');
    });

    test('are localized for en', () {
      final strings = Strings(AppLocale.en);
      expect(strings.shareLinkPageGetIos, 'Download on the App Store');
      expect(strings.shareLinkPageGetAndroid, 'Get it on Google Play');
    });
  });
}
