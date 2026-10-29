import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

enum Flavor { dev, stg, prod }

final class Environment {
  const Environment._({
    required this.flavor,
    required this.firebaseOptions,
    required this.firebaseProjectId,
    required this.emulatorHost,
    required this.appCheckSiteKey,
  });

  factory Environment.fromEnvironment() => Environment.resolve(
    flavor: const String.fromEnvironment('FLAVOR', defaultValue: 'dev'),
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    firebaseProjectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
    emulatorHost: const String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: '127.0.0.1'),
    appCheckSiteKey: const String.fromEnvironment('APP_CHECK_SITE_KEY'),
    isDebug: kDebugMode,
  );

  factory Environment.resolve({
    required String flavor,
    required FirebaseOptions firebaseOptions,
    required bool isDebug,
    String firebaseProjectId = '',
    String emulatorHost = '127.0.0.1',
    String appCheckSiteKey = '',
  }) {
    final selectedFlavor = switch (flavor) {
      'dev' => Flavor.dev,
      'stg' => Flavor.stg,
      'prod' => Flavor.prod,
      _ => throw StateError('FLAVOR must be dev, stg, or prod.'),
    };
    final usesEmulators = selectedFlavor == Flavor.dev;
    final projectId = usesEmulators && firebaseProjectId.isEmpty ? 'dev-flutterkaigi-2026' : firebaseProjectId;
    if (projectId.isEmpty) {
      throw StateError('FIREBASE_PROJECT_ID is required for staging and production.');
    }
    if (!usesEmulators && projectId != firebaseOptions.projectId) {
      throw StateError('FIREBASE_PROJECT_ID does not match the generated Firebase options.');
    }
    if (usesEmulators && emulatorHost.trim().isEmpty) {
      throw StateError('FIREBASE_EMULATOR_HOST must not be empty.');
    }
    if (!usesEmulators && !isDebug && appCheckSiteKey.trim().isEmpty) {
      throw StateError('APP_CHECK_SITE_KEY is required for release web builds.');
    }
    return Environment._(
      flavor: selectedFlavor,
      // Keep OAuth helper settings while selecting the same emulator project
      // used by the seed tool, even when the generated options target staging.
      firebaseOptions: usesEmulators ? firebaseOptions.copyWith(projectId: projectId) : firebaseOptions,
      firebaseProjectId: projectId,
      emulatorHost: emulatorHost,
      appCheckSiteKey: appCheckSiteKey,
    );
  }

  final Flavor flavor;
  final FirebaseOptions firebaseOptions;
  final String firebaseProjectId;
  final String emulatorHost;
  final String appCheckSiteKey;

  bool get usesEmulators => flavor == Flavor.dev;
}
