import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase for local development against the emulator suite.
///
/// This package is intentionally local/dev only for now. Production and
/// staging should be added when real Firebase projects exist — once
/// `flutterfire configure` generates `firebase_options.dart`, pass
/// `DefaultFirebaseOptions.currentPlatform` to [ensureInitialized] (or add a
/// dedicated initializer). Call [ensureInitialized] once during app startup
/// (for example in `main()`) before any repository is used.
final class FirebaseInitializer {
  const FirebaseInitializer._();

  static bool _emulatorConfigured = false;

  /// Whether [ensureInitialized] wired Firestore, Auth, and Functions to the
  /// local Emulator Suite.
  static bool get emulatorConfigured => _emulatorConfigured;

  /// Initializes the default [FirebaseApp], and optionally wires Firestore and
  /// Auth to the local emulator suite.
  ///
  /// By default, `options == null` wires Firestore, Auth, and Functions to the
  /// local emulator suite. Set [useEmulators] explicitly when Web OAuth needs
  /// valid FlutterFire-generated [options] for the SDK helper page while all
  /// data and authentication requests must still remain local.
  ///
  /// Safe to call more than once: Firebase is only initialized when no app
  /// exists yet, and the emulator wiring is applied a single time.
  /// The region every Cloud Functions callable in this project deploys to.
  static const functionsRegion = 'asia-northeast1';

  static Future<void> ensureInitialized({
    FirebaseOptions? options,
    bool? useEmulators,
    String projectId = 'dev-flutterkaigi-2026',
    String host = 'localhost',
    int firestorePort = 8080,
    int authPort = 9099,
    int functionsPort = 5001,
  }) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: options ?? _localOptions(projectId),
      );
    }

    // Preserve the package's existing `options == null` development behavior,
    // while allowing Web apps to initialize with valid OAuth helper settings
    // and still route every Firebase service to the local emulators.
    final shouldUseEmulators = useEmulators ?? options == null;
    if (!shouldUseEmulators || _emulatorConfigured) {
      return;
    }
    _emulatorConfigured = true;

    FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
    await FirebaseAuth.instance.useAuthEmulator(host, authPort);
    FirebaseFunctions.instanceFor(region: functionsRegion).useFunctionsEmulator(host, functionsPort);
  }

  /// Dummy [FirebaseOptions] that are sufficient for the emulator suite.
  ///
  /// The emulators do not validate these values, but `Firebase.initializeApp`
  /// requires them and the native SDKs validate their format:
  /// - `appId` platform segment — see [_appIdPlatform].
  /// - `apiKey` must be 39 characters, start with `A`, and be base64 url-safe
  ///   (validated by FirebaseInstallations on iOS).
  static FirebaseOptions _localOptions(String projectId) => FirebaseOptions(
    apiKey: 'AIzaSyDUMMY_LOCAL_EMULATOR_000000000000',
    appId: '1:000000000000:${_appIdPlatform()}:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: projectId,
    // The Web Auth SDK requires authDomain before it can start popup/redirect
    // OAuth flows, even when the request itself is routed to Auth Emulator.
    authDomain: '$projectId.firebaseapp.com',
  );

  /// The platform segment of `appId` (`1:<sender>:<platform>:<hash>`).
  ///
  /// The native Firebase SDKs validate this segment: iOS/macOS require `ios`
  /// and Android requires `android`, otherwise `Firebase.initializeApp` throws
  /// an invalid `GOOGLE_APP_ID` exception. Web does not validate the format.
  static String _appIdPlatform() {
    if (kIsWeb) {
      return 'web';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'ios';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 'ios';
    }
  }
}
