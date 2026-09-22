/// Generates verification files for the Flutter Web app deployment.
///
/// Run from the repository root after `flutter build web`:
///
/// ```sh
/// APPLE_TEAM_ID=ABCDE12345 IOS_BUNDLE_ID=jp.flutterkaigi.conf2026 \
///   ANDROID_PACKAGE_NAME=jp.flutterkaigi.conf2026 \
///   ANDROID_SHA256_FINGERPRINTS=AA:BB:... \
///   dart tool/generate_app_links.dart --environment=prod
/// ```
///
/// Preview deployments use `--environment=stg`, with both app identifiers
/// set to `jp.flutterkaigi.conf2026.stg` and the STG signing fingerprints.
/// All configuration is required: a missing or invalid value fails the
/// deployment instead of silently shipping stale verification files.
library;

import 'dart:convert';
import 'dart:io';

const defaultAppLinksOutputDirectory = 'apps/app/build/web/.well-known';

void main(List<String> arguments) {
  try {
    String? environment;
    String? outputDirectory;
    for (final argument in arguments) {
      if (argument.startsWith('--environment=') && environment == null) {
        environment = argument.substring('--environment='.length);
      } else if (argument.startsWith('--output-dir=') && outputDirectory == null) {
        outputDirectory = argument.substring('--output-dir='.length);
      } else {
        throw FormatException('Unknown or duplicate argument: $argument');
      }
    }
    if (environment == null) {
      throw const FormatException('Required argument: --environment=prod|stg');
    }
    if (outputDirectory != null && outputDirectory.trim().isEmpty) {
      throw const FormatException('--output-dir must not be empty.');
    }

    final directory = Directory(outputDirectory ?? defaultAppLinksOutputDirectory);
    generateAppLinks(environment: environment, variables: Platform.environment, outputDirectory: directory);
    stdout.writeln('Generated $environment app link verification files in ${directory.path}.');
  } on FormatException catch (error) {
    stderr.writeln('App link configuration error: ${error.message}');
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln('Could not write app link verification files: $error');
    exitCode = 73;
  }
}

/// Validates the deployment configuration, then writes both verification files.
///
/// Throws [FormatException] before touching output files when any configuration
/// is invalid. [FileSystemException] propagates if either file cannot be written.
void generateAppLinks({
  required String environment,
  required Map<String, String> variables,
  required Directory outputDirectory,
}) {
  final expectedAppId = switch (environment) {
    'prod' => 'jp.flutterkaigi.conf2026',
    'stg' => 'jp.flutterkaigi.conf2026.stg',
    _ => throw const FormatException('--environment must be prod or stg.'),
  };
  final teamId = _requiredVariable(variables, 'APPLE_TEAM_ID');
  if (!RegExp(r'^[A-Z0-9]{10}$').hasMatch(teamId)) {
    throw const FormatException('APPLE_TEAM_ID must be a 10-character uppercase alphanumeric Apple Team ID.');
  }
  final bundleId = _requiredVariable(variables, 'IOS_BUNDLE_ID');
  final packageName = _requiredVariable(variables, 'ANDROID_PACKAGE_NAME');
  for (final entry in {'IOS_BUNDLE_ID': bundleId, 'ANDROID_PACKAGE_NAME': packageName}.entries) {
    if (entry.value != expectedAppId) {
      throw FormatException('${entry.key} must be $expectedAppId for --environment=$environment.');
    }
  }

  final fingerprintPattern = RegExp(r'^(?:[A-Fa-f0-9]{2}:){31}[A-Fa-f0-9]{2}$');
  final fingerprints = _requiredVariable(
    variables,
    'ANDROID_SHA256_FINGERPRINTS',
  ).split(',').map((fingerprint) => fingerprint.trim()).toList();
  if (fingerprints.any((fingerprint) => !fingerprintPattern.hasMatch(fingerprint))) {
    throw const FormatException(
      'ANDROID_SHA256_FINGERPRINTS must contain comma-separated SHA-256 fingerprints '
      '(32 colon-separated hexadecimal bytes each).',
    );
  }

  final apple = {
    'applinks': {
      'apps': <String>[],
      'details': [
        {
          'appID': '$teamId.$bundleId',
          'paths': ['NOT /.well-known/*', '/', '/*'],
        },
      ],
    },
  };
  final android = [
    {
      'relation': ['delegate_permission/common.handle_all_urls'],
      'target': {
        'namespace': 'android_app',
        'package_name': packageName,
        'sha256_cert_fingerprints': fingerprints.map((fingerprint) => fingerprint.toUpperCase()).toList(),
      },
    },
  ];

  outputDirectory.createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  File('${outputDirectory.path}/apple-app-site-association').writeAsStringSync('${encoder.convert(apple)}\n');
  File('${outputDirectory.path}/assetlinks.json').writeAsStringSync('${encoder.convert(android)}\n');
}

String _requiredVariable(Map<String, String> variables, String name) {
  final value = variables[name]?.trim() ?? '';
  if (value.isEmpty) {
    throw FormatException('$name is required.');
  }
  return value;
}
