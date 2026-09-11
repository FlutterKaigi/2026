import 'package:app/core/i18n/strings.g.dart';
import 'package:firebase_core/firebase_core.dart';

String supportLtErrorMessage(Translations t, Object error) {
  if (error case FirebaseException(:final code)) {
    return switch (code) {
      'invalid-argument' => t.supportLt.invalidFormat,
      'not-found' => t.supportLt.invalidCode,
      'resource-exhausted' => t.supportLt.rateLimited,
      'unavailable' || 'deadline-exceeded' || 'network-request-failed' => t.supportLt.networkError,
      'unauthenticated' => t.supportLt.sessionExpired,
      'permission-denied' => t.supportLt.permissionDenied,
      _ => t.supportLt.registrationFailed,
    };
  }
  return t.supportLt.registrationFailed;
}

/// Whether [error] concerns the entered code itself, so the code boxes are
/// highlighted along with the message.
bool isSupportLtCodeError(Object error) =>
    error is FirebaseException && const {'invalid-argument', 'not-found'}.contains(error.code);
