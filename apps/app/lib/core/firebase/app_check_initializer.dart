import 'package:app/core/provider/environment.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Configures App Check before the app accesses protected Firebase services.
Future<void> ensureAppCheckInitialized(Environment environment) async {
  // The development flavor uses the local Firebase Emulator Suite, which
  // does not require App Check attestation.
  if (environment.flavor == Flavor.develop) {
    return;
  }

  await FirebaseAppCheck.instance.activate(
    providerWeb: _webProvider(environment),
    providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode ? const AppleDebugProvider() : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );
}

WebProvider? _webProvider(Environment environment) {
  if (!kIsWeb) {
    return null;
  }
  if (kDebugMode) {
    return WebDebugProvider();
  }

  final siteKey = environment.appCheckSiteKey;
  if (siteKey.isEmpty) {
    throw StateError(
      'APP_CHECK_SITE_KEY is required for release web builds.',
    );
  }
  return ReCaptchaEnterpriseProvider(siteKey);
}
