import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Initializes the default [FirebaseApp], and optionally wires Firestore and
  /// Auth to the local emulator suite.
  ///
  /// When [options] is `null`, Firestore and Auth are wired to the local
  /// emulator suite. Pass `DefaultFirebaseOptions.currentPlatform` from a
  /// `flutterfire configure`-generated `firebase_options.dart` to use a real
  /// Firebase project instead.
  ///
  /// Safe to call more than once: Firebase is only initialized when no app
  /// exists yet, and the emulator wiring is applied a single time.
  static Future<void> ensureInitialized({
    FirebaseOptions? options,
    String projectId = 'dev-flutterkaigi-2026',
    String host = 'localhost',
    int firestorePort = 8080,
    int authPort = 9099,
  }) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: options ?? _localOptions(projectId),
      );
    }

    if (options != null || _emulatorConfigured) {
      return;
    }
    _emulatorConfigured = true;

    FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
    await FirebaseAuth.instance.useAuthEmulator(host, authPort);
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
