/// Generates the Universal Links (iOS) / App Links (Android) verification
/// files under `apps/website/web/.well-known/` — `jaspr build` copies
/// dot-directories under `web/` into `build/jaspr` verbatim, so anything
/// written here ships with the site.
///
/// The values these files need (the Apple Team ID and the Android release
/// signing certificate's SHA-256 fingerprints) are not in this repo — see
/// `.github/APP_DELIVERY.md`. Each platform's file is written only when its
/// Repository Variables are set; an unset platform is skipped (not written
/// with a placeholder), so a deploy before Apple/Android delivery is fully
/// configured still succeeds, just without that platform's verification
/// file (and without Universal Links / App Links working for it yet).
///
/// Run via:
///
/// ```sh
/// APPLE_TEAM_ID=... IOS_BUNDLE_ID=jp.flutterkaigi.conf2026 \
///   ANDROID_PACKAGE_NAME=jp.flutterkaigi.conf2026 \
///   PROD_ANDROID_SHA256_FINGERPRINTS=AA:BB:...,CC:DD:... \
///   dart run tool/generate_well_known.dart
/// ```
library;

import 'dart:convert';
import 'dart:io';

const outDir = 'apps/website/web/.well-known';

/// The share-link path Universal Links / App Links should open the app for
/// — matches `exchangeShareBaseUrl` in
/// `apps/app/lib/feature/exchange/data/exchange_token.dart`.
const _shareLinkPath = '/x/*';

Future<void> main() async {
  final apple = appleAppSiteAssociation(Platform.environment);
  final android = assetlinks(Platform.environment);
  if (apple != null) {
    _write('apple-app-site-association', apple);
  } else {
    stdout.writeln('warning: APPLE_TEAM_ID / IOS_BUNDLE_ID not set; skipping apple-app-site-association.');
  }
  if (android != null) {
    _write('assetlinks.json', android);
  } else {
    stdout.writeln(
      'warning: ANDROID_PACKAGE_NAME / PROD_ANDROID_SHA256_FINGERPRINTS not set; skipping assetlinks.json.',
    );
  }
  if (apple == null && android == null) {
    stdout.writeln('No Universal Links / App Links Repository Variables configured; skipping $outDir.');
  }
}

/// The `apple-app-site-association` content for [env], or `null` when
/// `APPLE_TEAM_ID` / `IOS_BUNDLE_ID` aren't both set.
Map<String, Object?>? appleAppSiteAssociation(Map<String, String> env) {
  final teamId = (env['APPLE_TEAM_ID'] ?? '').trim();
  final bundleId = (env['IOS_BUNDLE_ID'] ?? '').trim();
  if (teamId.isEmpty || bundleId.isEmpty) {
    return null;
  }
  return {
    'applinks': {
      'apps': <String>[],
      'details': [
        {
          'appID': '$teamId.$bundleId',
          'paths': [_shareLinkPath],
        },
      ],
    },
  };
}

/// The `assetlinks.json` content for [env], or `null` when
/// `ANDROID_PACKAGE_NAME` / `PROD_ANDROID_SHA256_FINGERPRINTS` aren't both
/// set (an empty fingerprint list counts as unset).
List<Object?>? assetlinks(Map<String, String> env) {
  final packageName = (env['ANDROID_PACKAGE_NAME'] ?? '').trim();
  final fingerprints = (env['PROD_ANDROID_SHA256_FINGERPRINTS'] ?? '')
      .split(',')
      .map((f) => f.trim())
      .where((f) => f.isNotEmpty)
      .toList();
  if (packageName.isEmpty || fingerprints.isEmpty) {
    return null;
  }
  return [
    {
      'relation': ['delegate_permission/common.handle_all_urls'],
      'target': {
        'namespace': 'android_app',
        'package_name': packageName,
        'sha256_cert_fingerprints': fingerprints,
      },
    },
  ];
}

void _write(String fileName, Object content) {
  final dir = Directory(outDir)..createSync(recursive: true);
  final file = File('${dir.path}/$fileName');
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(content)}\n');
  stdout.writeln('Wrote ${file.path}');
}
