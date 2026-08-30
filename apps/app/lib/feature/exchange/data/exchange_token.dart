import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_token.freezed.dart';

/// Base URL for the profile-exchange QR payload.
///
/// Kept URL-shaped (rather than the bare token) so a future share-link
/// handler (Phase 3) can reuse the same route without changing the QR format.
const exchangeShareBaseUrl = 'https://2026.flutterkaigi.jp/x';

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

  /// The QR code payload embedding [value].
  String get qrPayload => '$exchangeShareBaseUrl/$value';
}

/// A token scanned from another attendee's QR code, with the uid it embeds.
typedef ScannedExchangeToken = ({String token, String otherUid});

/// Matches a `v1.<uid>.<exp>.<sig>` token (see
/// `functions/src/profile_exchange.ts`'s `buildExchangeToken`). The uid is
/// captured so the client can address `users/{me}/exchanges/{otherUid}`
/// without decoding the signature — the signature itself is opaque here and
/// verified server-side by the `onProfileExchangeCreated` trigger.
final _tokenPattern = RegExp(r'^v1\.([^.]+)\.\d+\.[0-9a-f]+$');

/// Validates scanned QR content as either the `$exchangeShareBaseUrl/<token>`
/// URL form or a bare token, and extracts the other attendee's uid from it.
///
/// Returns `null` when [raw] matches neither shape.
ScannedExchangeToken? parseScannedExchangeToken(String raw) {
  final trimmed = raw.trim();
  final candidate = trimmed.startsWith('$exchangeShareBaseUrl/')
      ? trimmed.substring(exchangeShareBaseUrl.length + 1)
      : trimmed;
  final match = _tokenPattern.firstMatch(candidate);
  if (match == null) {
    return null;
  }
  return (token: candidate, otherUid: match.group(1)!);
}
