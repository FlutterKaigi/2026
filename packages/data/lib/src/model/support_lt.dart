/// Origins hosting the attendee app. Links on these origins open the installed
/// app talking to the matching backend, or the web app when it is not installed.
const productionAppOrigin = 'https://2026-app.flutterkaigi.jp';
const stagingAppOrigin = 'https://stg-flutterkaigi-2026-conference-app.flutterkaigi.workers.dev';

/// App path of the Support LT registration page. The attendance QR code links
/// to this path followed by the registration code.
const supportLtLinkPath = '/account/support-lt';

final _codePattern = RegExp(r'^[0-9]{6}$');

/// Whether [value] has the shape of a Support LT registration code.
bool isSupportLtCode(String value) => _codePattern.hasMatch(value);

/// The attendance QR code's content for [code].
///
/// The caller chooses the origin for its backend environment. Local emulator
/// builds pass null and show a bare code instead of linking to a live app.
String supportLtQrPayload(String code, {required String? origin}) =>
    origin == null ? code : '$origin$supportLtLinkPath/$code';

/// Extracts the registration code from a scanned attendance QR code: an allowed
/// origin's link or a bare code. Scanners pass their environment's
/// [allowedOrigins] so a production QR code is not submitted to the staging
/// backend, or vice versa. The server still verifies the code itself.
///
/// Returns `null` when [raw] matches neither shape.
String? parseSupportLtQrPayload(String raw, {required Set<String> allowedOrigins}) {
  final trimmed = raw.trim();
  if (isSupportLtCode(trimmed)) {
    return trimmed;
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
  const prefix = '$supportLtLinkPath/';
  if (!uri.path.startsWith(prefix)) {
    return null;
  }
  final code = uri.path.substring(prefix.length);
  return isSupportLtCode(code) ? code : null;
}

/// The registration code currently issued by the event staff.
final class SupportLtCode {
  const SupportLtCode({required this.code, required this.issuedAt});

  final String code;
  final DateTime issuedAt;
}

/// An attendee whose Support LT registration was verified by the server.
final class SupportLtRegistration {
  const SupportLtRegistration({required this.uid, required this.displayName, required this.registeredAt});

  final String uid;
  final String displayName;
  final DateTime registeredAt;
}
