import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../tool/generate_app_links.dart';

void main() {
  final fingerprint = List.filled(32, 'AB').join(':');
  final secondFingerprint = List.filled(32, 'cd').join(':');
  final scriptPath = File('tool/generate_app_links.dart').absolute.path;
  late Directory temporaryDirectory;
  late Directory outputDirectory;

  Map<String, String> variablesFor(String environment) {
    final appId = 'jp.flutterkaigi.conf2026${environment == 'stg' ? '.stg' : ''}';
    return {
      'APPLE_TEAM_ID': 'ABCDE12345',
      'IOS_BUNDLE_ID': appId,
      'ANDROID_PACKAGE_NAME': appId,
      'ANDROID_SHA256_FINGERPRINTS': fingerprint,
    };
  }

  Future<ProcessResult> runCli(List<String> arguments, Map<String, String> variables) {
    return Process.run(
      Platform.resolvedExecutable,
      [
        scriptPath,
        ...arguments,
        if (!arguments.any((argument) => argument.startsWith('--output-dir='))) '--output-dir=${outputDirectory.path}',
      ],
      environment: variables,
      includeParentEnvironment: false,
    );
  }

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync('generate-app-links-test-');
    outputDirectory = Directory('${temporaryDirectory.path}/web/.well-known');
  });

  tearDown(() {
    temporaryDirectory.deleteSync(recursive: true);
  });

  group('generateAppLinks', () {
    for (final environment in ['prod', 'stg']) {
      test('generates full-route association files for $environment', () {
        final variables = variablesFor(environment);
        generateAppLinks(environment: environment, variables: variables, outputDirectory: outputDirectory);

        expect(jsonDecode(File('${outputDirectory.path}/apple-app-site-association').readAsStringSync()), {
          'applinks': {
            'apps': <String>[],
            'details': [
              {
                'appID': 'ABCDE12345.${variables['IOS_BUNDLE_ID']}',
                'paths': ['NOT /.well-known/*', '/', '/*'],
              },
            ],
          },
        });
        expect(jsonDecode(File('${outputDirectory.path}/assetlinks.json').readAsStringSync()), [
          {
            'relation': ['delegate_permission/common.handle_all_urls'],
            'target': {
              'namespace': 'android_app',
              'package_name': variables['ANDROID_PACKAGE_NAME'],
              'sha256_cert_fingerprints': [fingerprint],
            },
          },
        ]);
        expect(outputDirectory.listSync(), hasLength(2));
      });
    }

    test('accepts multiple fingerprints and normalizes hexadecimal case', () {
      generateAppLinks(
        environment: 'prod',
        variables: variablesFor('prod')..['ANDROID_SHA256_FINGERPRINTS'] = ' $fingerprint, $secondFingerprint ',
        outputDirectory: outputDirectory,
      );

      final android = jsonDecode(File('${outputDirectory.path}/assetlinks.json').readAsStringSync()) as List;
      expect(android.single['target']['sha256_cert_fingerprints'], [fingerprint, secondFingerprint.toUpperCase()]);
    });

    for (final variable in variablesFor('prod').keys) {
      for (final value in <String?>[null, '   ']) {
        test('rejects $variable when ${value == null ? 'missing' : 'blank'} before writing either file', () {
          final variables = variablesFor('prod');
          if (value == null) {
            variables.remove(variable);
          } else {
            variables[variable] = value;
          }

          expect(
            () => generateAppLinks(environment: 'prod', variables: variables, outputDirectory: outputDirectory),
            throwsFormatException,
          );
          expect(outputDirectory.existsSync(), isFalse);
        });
      }
    }

    for (final environment in ['prod', 'stg']) {
      for (final variable in ['IOS_BUNDLE_ID', 'ANDROID_PACKAGE_NAME']) {
        test('rejects the other environment in $variable for $environment', () {
          final variables = variablesFor(environment);
          variables[variable] = variablesFor(environment == 'prod' ? 'stg' : 'prod')[variable]!;

          expect(
            () => generateAppLinks(environment: environment, variables: variables, outputDirectory: outputDirectory),
            throwsFormatException,
          );
          expect(outputDirectory.existsSync(), isFalse);
        });
      }
    }

    test('rejects an unsupported environment', () {
      expect(
        () => generateAppLinks(environment: 'dev', variables: variablesFor('prod'), outputDirectory: outputDirectory),
        throwsFormatException,
      );
    });

    test('rejects an invalid Apple Team ID', () {
      expect(
        () => generateAppLinks(
          environment: 'prod',
          variables: variablesFor('prod')..['APPLE_TEAM_ID'] = 'placeholder',
          outputDirectory: outputDirectory,
        ),
        throwsFormatException,
      );
    });

    for (final invalidFingerprint in [
      'AA:BB',
      List.filled(32, 'GG').join(':'),
      List.filled(32, 'AB').join(),
      '$fingerprint,',
      ',$fingerprint',
      '$fingerprint,not-a-fingerprint',
    ]) {
      test('rejects malformed SHA-256 fingerprint list: $invalidFingerprint', () {
        expect(
          () => generateAppLinks(
            environment: 'prod',
            variables: variablesFor('prod')..['ANDROID_SHA256_FINGERPRINTS'] = invalidFingerprint,
            outputDirectory: outputDirectory,
          ),
          throwsFormatException,
        );
        expect(outputDirectory.existsSync(), isFalse);
      });
    }
  });

  group('CLI', () {
    test('defaults to the Flutter Web build verification directory', () async {
      final result = await Process.run(
        Platform.resolvedExecutable,
        [scriptPath, '--environment=prod'],
        environment: variablesFor('prod'),
        includeParentEnvironment: false,
        workingDirectory: temporaryDirectory.path,
      );

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(Directory('${temporaryDirectory.path}/$defaultAppLinksOutputDirectory').listSync(), hasLength(2));
    });

    test('returns success only after producing both files in the requested directory', () async {
      final result = await runCli(['--environment=stg'], variablesFor('stg'));

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(outputDirectory.listSync(), hasLength(2));
      expect(File('${outputDirectory.path}/apple-app-site-association').readAsStringSync(), contains('.conf2026.stg'));
      expect(File('${outputDirectory.path}/assetlinks.json').readAsStringSync(), contains('.conf2026.stg'));
    });

    test('fails missing configuration even when old verification files exist', () async {
      generateAppLinks(environment: 'prod', variables: variablesFor('prod'), outputDirectory: outputDirectory);
      final originalApple = File('${outputDirectory.path}/apple-app-site-association').readAsStringSync();
      final originalAndroid = File('${outputDirectory.path}/assetlinks.json').readAsStringSync();

      final result = await runCli(['--environment=stg'], variablesFor('stg')..remove('ANDROID_SHA256_FINGERPRINTS'));

      expect(result.exitCode, 64);
      expect(result.stderr, contains('ANDROID_SHA256_FINGERPRINTS is required'));
      expect(result.stdout, isEmpty);
      expect(File('${outputDirectory.path}/apple-app-site-association').readAsStringSync(), originalApple);
      expect(File('${outputDirectory.path}/assetlinks.json').readAsStringSync(), originalAndroid);
    });

    test('fails a production/preview identifier mismatch', () async {
      final result = await runCli(['--environment=stg'], variablesFor('prod'));

      expect(result.exitCode, 64);
      expect(result.stderr, contains('IOS_BUNDLE_ID must be jp.flutterkaigi.conf2026.stg'));
      expect(outputDirectory.existsSync(), isFalse);
    });

    test('fails malformed fingerprints instead of generating partial output', () async {
      final result = await runCli(
        ['--environment=prod'],
        variablesFor('prod')..['ANDROID_SHA256_FINGERPRINTS'] = 'AA:BB',
      );

      expect(result.exitCode, 64);
      expect(result.stderr, contains('32 colon-separated hexadecimal bytes'));
      expect(outputDirectory.existsSync(), isFalse);
    });

    for (final arguments in [
      <String>[],
      ['--environment=dev'],
      ['--environment=prod', '--environment=stg'],
      ['--environment=prod', '--unknown=value'],
      ['--environment=prod', '--output-dir='],
    ]) {
      test('rejects invalid arguments $arguments', () async {
        final result = await runCli(arguments, variablesFor('prod'));

        expect(result.exitCode, 64);
        expect(result.stderr, contains('App link configuration error'));
        expect(outputDirectory.existsSync(), isFalse);
      });
    }

    test('returns failure when verification files cannot be written', () async {
      outputDirectory.createSync(recursive: true);
      Directory('${outputDirectory.path}/assetlinks.json').createSync();

      final result = await runCli(['--environment=prod'], variablesFor('prod'));

      expect(result.exitCode, 73);
      expect(result.stderr, contains('Could not write app link verification files'));
      expect(result.stdout, isEmpty);
    });
  });
}
