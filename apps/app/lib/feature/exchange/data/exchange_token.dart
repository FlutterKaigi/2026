import 'package:clock/clock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_token.freezed.dart';

/// Origins hosting exchange links. The website origin remains scan-compatible
/// with QR codes issued before the app received its own canonical origin.
const productionExchangeOrigin = 'https://2026-app.flutterkaigi.jp';
const stagingExchangeOrigin = 'https://stg-flutterkaigi-2026-conference-app.flutterkaigi.workers.dev';
const legacyExchangeOrigin = 'https://2026.flutterkaigi.jp';

/// A signed, time-limited token for displaying the signed-in user's QR code.
///
/// Issued by the `issueExchangeToken` callable function and cached on-device
/// so the QR code stays displayable offline until [expiresAt].
@freezed
abstract class ExchangeToken with _$ExchangeToken {
  const factory ExchangeToken({
    required String value,
    required DateTime expiresAt,
  }) = _ExchangeToken;

  const ExchangeToken._();

  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  /// The caller chooses the origin for its backend environment. Local emulator
  /// builds pass null and display a bare token instead of linking to a live app.
  String qrPayload({required String? origin}) => origin == null ? value : '$origin/x/$value';
}

/// A token scanned from another attendee's QR code, with the uid it embeds.
typedef ScannedExchangeToken = ({String token, String otherUid});

/// Matches a `v1.<uid>.<exp>.<sig>` token (see
/// `functions/src/profile_exchange.ts`'s `buildExchangeToken`). The uid is
/// captured so the client can address `users/{me}/exchanges/{otherUid}`
/// without decoding the signature — the signature itself is opaque here and
/// verified server-side by the `onProfileExchangeCreated` trigger.
final _tokenPattern = RegExp(r'^v1\.([^.]+)\.\d+\.[0-9a-f]+$');

/// Validates an allowed origin's `/x/<token>` URL or a bare token, and extracts
/// the other attendee's uid. Scanners pass their environment's [allowedOrigins]
/// so a production QR cannot be exchanged against the staging backend, or vice
/// versa. Bare tokens remain supported for server responses and local QR codes;
/// their signatures are always checked by the backend.
///
/// Returns `null` when [raw] matches neither shape.
ScannedExchangeToken? parseScannedExchangeToken(
  String raw, {
  Set<String> allowedOrigins = const {productionExchangeOrigin, legacyExchangeOrigin},
}) {
  final trimmed = raw.trim();
  var candidate = trimmed;
  if (!_tokenPattern.hasMatch(candidate)) {
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        !allowedOrigins.contains(uri.origin) ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.pathSegments.length != 2 ||
        uri.pathSegments.first != 'x') {
      return null;
    }
    candidate = uri.pathSegments.last;
  }
  final match = _tokenPattern.firstMatch(candidate);
  if (match == null) {
    return null;
  }
  return (token: candidate, otherUid: match.group(1)!);
}

/// Best-effort local read of a token's embedded `exp` claim, for showing a
/// "link expired" message without a round trip when a share link (unlike a
/// freshly displayed QR) may be opened long after it was issued. Not the
/// authoritative check — `onProfileExchangeCreated` still verifies the
/// signature and expiry server-side regardless of this result, so a `false`
/// here (including for a malformed token, deferred to that check) never
/// grants anything on its own.
bool isExchangeTokenExpired(String token) {
  final parts = token.split('.');
  if (parts.length != 4) {
    return false;
  }
  final expSeconds = int.tryParse(parts[2]);
  if (expSeconds == null) {
    return false;
  }
  // package:clock (not DateTime.now() directly), matching ExchangeCode.isExpired,
  // so widget tests can advance this via the FakeAsync clock testWidgets runs
  // every test body inside.
  return clock.now().isAfter(DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000));
}
