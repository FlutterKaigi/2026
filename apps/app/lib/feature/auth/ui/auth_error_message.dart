import 'package:app/core/i18n/strings.g.dart';
import 'package:data/user.dart';

/// Maps a [FirebaseAuthException] to a localized user-facing message.
///
/// Returns `null` when the user canceled the flow themselves, in which case
/// no feedback should be shown.
String? authErrorMessage(Translations t, FirebaseAuthException exception) => switch (exception.code) {
  // The user closed the provider popup / browser flow on purpose.
  'canceled' ||
  'cancelled-popup-request' ||
  'popup-closed-by-user' ||
  'user-cancelled' ||
  'web-context-canceled' ||
  'web-context-cancelled' => null,
  'invalid-email' => t.auth.error.invalidEmail,
  'user-disabled' => t.auth.error.userDisabled,
  // Firebase reports the credential variants with one opaque code when email
  // enumeration protection is enabled; the older split codes are kept for the
  // Auth Emulator, which still returns them.
  'invalid-credential' || 'user-not-found' || 'wrong-password' => t.auth.error.invalidCredential,
  'email-already-in-use' => t.auth.error.emailAlreadyInUse,
  'weak-password' => t.auth.error.weakPassword,
  'too-many-requests' => t.auth.error.tooManyRequests,
  'network-request-failed' => t.auth.error.network,
  'requires-recent-login' => t.auth.error.requiresRecentLogin,
  'user-mismatch' => t.auth.error.userMismatch,
  'apple-token-revocation-failed' => t.auth.error.appleTokenRevocationFailed,
  _ => t.auth.error.unknown,
};
