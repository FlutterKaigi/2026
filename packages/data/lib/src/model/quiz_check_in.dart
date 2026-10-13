final _codePattern = RegExp(r'^[0-9]{6}$');

/// Whether [value] has the shape of a quiz check-in code.
bool isQuizCheckInCode(String value) => _codePattern.hasMatch(value);

/// App path that checks in to [eventId]; the venue QR code links to this path
/// followed by the check-in code.
String quizCheckInLinkPath(String eventId) => '/account/quiz/$eventId/check-in';

/// The venue check-in QR code's content.
///
/// The caller chooses the origin for its backend environment. Local emulator
/// builds pass null and show a bare code instead of linking to a live app.
String quizCheckInQrPayload(String eventId, String code, {required String? origin}) =>
    origin == null ? code : '$origin${quizCheckInLinkPath(eventId)}/$code';

/// Reads a scanned check-in QR code: an allowed origin's link, which names its
/// event, or a bare code, which does not. Scanners pass their environment's
/// [allowedOrigins] so a production QR code is not submitted to the staging
/// backend, or vice versa. The server still verifies the code itself.
///
/// Returns `null` when [raw] matches neither shape.
({String? eventId, String code})? parseQuizCheckInQrPayload(String raw, {required Set<String> allowedOrigins}) {
  final trimmed = raw.trim();
  if (isQuizCheckInCode(trimmed)) {
    return (eventId: null, code: trimmed);
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null ||
      uri.scheme != 'https' ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      !allowedOrigins.contains(uri.origin) ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }
  return switch (uri.pathSegments) {
    ['account', 'quiz', final eventId, 'check-in', final code] when eventId.isNotEmpty && isQuizCheckInCode(code) => (
      eventId: eventId,
      code: code,
    ),
    _ => null,
  };
}
