// ignore_for_file: do_not_use_environment

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'environment.freezed.dart';

/// Provides the [Environment] resolved from compile-time `--dart-define`s.
///
/// Overridden in `main()` with the value resolved at startup so it can be read
/// synchronously anywhere in the widget tree.
final environmentProvider = Provider<Environment>(
  (ref) => Environment.fromEnvironment(),
);

/// Compile-time configuration supplied via `--dart-define-from-file`.
@freezed
abstract class Environment with _$Environment {
  const factory Environment({
    required String appIdSuffix,
    required String appName,
    required Flavor flavor,
    required String firebaseProjectId,
    required String firestoreEmulatorHost,
    required String androidFirestoreEmulatorHost,
  }) = _Environment;

  const Environment._();

  /// Reads configuration from `--dart-define` values, defaulting to develop.
  factory Environment.fromEnvironment() => Environment(
    appIdSuffix: const String.fromEnvironment('APP_ID_SUFFIX'),
    appName: const String.fromEnvironment(
      'APP_NAME',
      defaultValue: '[DEV] FlutterKaigi 2026',
    ),
    flavor: Flavor.values.firstWhere(
      (flavor) => flavor.shortName == const String.fromEnvironment('FLAVOR', defaultValue: 'dev'),
    ),
    firebaseProjectId: const String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'dev-flutterkaigi-2026',
    ),
    firestoreEmulatorHost: const String.fromEnvironment(
      'FIRESTORE_EMULATOR_HOST',
      defaultValue: 'localhost:8080',
    ),
    androidFirestoreEmulatorHost: const String.fromEnvironment(
      'FIRESTORE_EMULATOR_HOST_ANDROID',
      defaultValue: '10.0.2.2:8080',
    ),
  );

  /// The Firestore emulator host appropriate for the current platform.
  String get firestoreHost {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return androidFirestoreEmulatorHost;
    }
    return firestoreEmulatorHost;
  }
}

/// Build flavor selected at compile time through the `FLAVOR` define.
enum Flavor {
  production('prod'),
  staging('stg'),
  develop('dev')
  ;

  const Flavor(this.shortName);

  /// The short identifier passed via `--dart-define=FLAVOR`.
  final String shortName;
}
