import 'package:test/test.dart';

import '../tool/generate_well_known.dart';

void main() {
  group('appleAppSiteAssociation', () {
    test('builds the applinks payload when both variables are set', () {
      final result = appleAppSiteAssociation({
        'APPLE_TEAM_ID': 'ABCDE12345',
        'IOS_BUNDLE_ID': 'jp.flutterkaigi.conf2026',
      });

      expect(result, {
        'applinks': {
          'apps': <String>[],
          'details': [
            {
              'appID': 'ABCDE12345.jp.flutterkaigi.conf2026',
              'paths': ['/x/*'],
            },
          ],
        },
      });
    });

    test('skips when only APPLE_TEAM_ID is set', () {
      expect(appleAppSiteAssociation({'APPLE_TEAM_ID': 'ABCDE12345'}), isNull);
    });

    test('skips when only IOS_BUNDLE_ID is set', () {
      expect(appleAppSiteAssociation({'IOS_BUNDLE_ID': 'jp.flutterkaigi.conf2026'}), isNull);
    });

    test('skips when neither variable is set', () {
      expect(appleAppSiteAssociation(const {}), isNull);
    });
  });

  group('assetlinks', () {
    test('builds the assetlinks payload when both variables are set', () {
      final result = assetlinks({
        'ANDROID_PACKAGE_NAME': 'jp.flutterkaigi.conf2026',
        'PROD_ANDROID_SHA256_FINGERPRINTS': 'AA:BB, CC:DD',
      });

      expect(result, [
        {
          'relation': ['delegate_permission/common.handle_all_urls'],
          'target': {
            'namespace': 'android_app',
            'package_name': 'jp.flutterkaigi.conf2026',
            'sha256_cert_fingerprints': ['AA:BB', 'CC:DD'],
          },
        },
      ]);
    });

    test('skips when only ANDROID_PACKAGE_NAME is set', () {
      expect(assetlinks({'ANDROID_PACKAGE_NAME': 'jp.flutterkaigi.conf2026'}), isNull);
    });

    test('skips when only PROD_ANDROID_SHA256_FINGERPRINTS is set', () {
      expect(assetlinks({'PROD_ANDROID_SHA256_FINGERPRINTS': 'AA:BB'}), isNull);
    });

    test('skips when the fingerprints variable is set but empty after trimming', () {
      expect(
        assetlinks({'ANDROID_PACKAGE_NAME': 'jp.flutterkaigi.conf2026', 'PROD_ANDROID_SHA256_FINGERPRINTS': ' , '}),
        isNull,
      );
    });

    test('skips when neither variable is set', () {
      expect(assetlinks(const {}), isNull);
    });
  });
}
