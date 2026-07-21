// ignore_for_file: avoid_classes_with_only_static_members

// Stub used only for dev/emulator analysis and tests.
// Delivery workflows replace lib/firebase_options.dart with FlutterFire CLI output.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
    apiKey: 'AIzaSyDUMMY_LOCAL_EMULATOR_000000000000',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'dev-flutterkaigi-2026',
  );
}
