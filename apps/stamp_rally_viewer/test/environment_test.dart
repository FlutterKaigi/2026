import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stamp_rally_viewer/environment.dart';

const _options = FirebaseOptions(
  apiKey: 'test-key',
  appId: '1:123:web:test',
  messagingSenderId: '123',
  projectId: 'flutterkaigi-test-stg',
  authDomain: 'flutterkaigi-test-stg.firebaseapp.com',
);

void main() {
  test('development uses the seeded emulator project and preserves OAuth helper settings', () {
    final environment = Environment.resolve(flavor: 'dev', firebaseOptions: _options, isDebug: false);

    expect(environment.usesEmulators, isTrue);
    expect(environment.firebaseProjectId, 'dev-flutterkaigi-2026');
    expect(environment.firebaseOptions.projectId, environment.firebaseProjectId);
    expect(environment.firebaseOptions.apiKey, _options.apiKey);
    expect(environment.firebaseOptions.authDomain, _options.authDomain);
    expect(environment.emulatorHost, '127.0.0.1');
  });

  test('development can select an emulator project and host', () {
    final environment = Environment.resolve(
      flavor: 'dev',
      firebaseOptions: _options,
      firebaseProjectId: 'demo-custom',
      emulatorHost: '192.168.1.10',
      isDebug: true,
    );

    expect(environment.firebaseOptions.projectId, 'demo-custom');
    expect(environment.emulatorHost, '192.168.1.10');
  });

  test('unknown flavors fail instead of silently connecting to emulators', () {
    expect(
      () => Environment.resolve(flavor: 'production', firebaseOptions: _options, isDebug: true),
      throwsStateError,
    );
  });

  for (final flavor in ['stg', 'prod']) {
    test('$flavor requires an explicit matching Firebase project', () {
      for (final project in ['', 'another-project']) {
        expect(
          () => Environment.resolve(
            flavor: flavor,
            firebaseOptions: _options,
            firebaseProjectId: project,
            appCheckSiteKey: 'site-key',
            isDebug: false,
          ),
          throwsStateError,
        );
      }
    });

    test('$flavor release requires App Check, while debug can use its debug provider', () {
      expect(
        () => Environment.resolve(
          flavor: flavor,
          firebaseOptions: _options,
          firebaseProjectId: _options.projectId,
          isDebug: false,
        ),
        throwsStateError,
      );

      final debug = Environment.resolve(
        flavor: flavor,
        firebaseOptions: _options,
        firebaseProjectId: _options.projectId,
        isDebug: true,
      );
      expect(debug.usesEmulators, isFalse);

      final release = Environment.resolve(
        flavor: flavor,
        firebaseOptions: _options,
        firebaseProjectId: _options.projectId,
        appCheckSiteKey: 'site-key',
        isDebug: false,
      );
      expect(release.firebaseOptions, same(_options));
      expect(release.appCheckSiteKey, 'site-key');
    });
  }
}
