/// Host used for the profile-exchange QR payload.
///
/// Kept as a plain URL (rather than the bare token) so it doubles as a
/// shareable link once Universal Links / App Links are wired up (see
/// issue-594.md section 5). The app itself never opens this URL; it only
/// builds it for the QR code and parses it back out of a scanned barcode.
const exchangeLinkOrigin = 'https://2026.flutterkaigi.jp';

/// Builds the QR payload for [token]: `https://2026.flutterkaigi.jp/x/<token>`.
Uri buildExchangeQrUri(String token) => Uri.parse('$exchangeLinkOrigin/x/$token');

/// A signed exchange token extracted from a scanned QR code, plus the uid it
/// claims to belong to.
///
/// [uid] is read directly off the unverified token (`v1.<uid>.<exp>.<sig>`)
/// for client-side checks only (self-scan detection, routing). The signature
/// and expiry are verified server-side by the `onProfileExchangeCreated`
/// Cloud Function trigger; this class does not and cannot verify them since
/// the signing secret never reaches the client.
class ScannedExchangeToken {
  const ScannedExchangeToken({required this.token, required this.uid});

  final String token;
  final String uid;
}

/// Parses a scanned barcode value into a [ScannedExchangeToken].
///
/// Accepts the `https://<host>/x/<token>` link format described in
/// issue-594.md section 4, and — defensively — a bare `v1.<uid>.<exp>.<sig>`
/// token in case a QR was generated without the URL wrapper. Returns `null`
/// when [raw] does not look like either shape, or the token itself is
/// malformed (wrong version, missing uid); this is a best-effort format check
/// only, not a signature/expiry check.
ScannedExchangeToken? parseScannedExchangeToken(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final token = _extractToken(trimmed);
  if (token == null) {
    return null;
  }

  final uid = _extractUid(token);
  if (uid == null) {
    return null;
  }

  return ScannedExchangeToken(token: token, uid: uid);
}

String? _extractToken(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) {
    final segments = uri.pathSegments;
    final linkIndex = segments.indexOf('x');
    if (linkIndex == -1 || linkIndex + 1 >= segments.length) {
      return null;
    }
    return segments[linkIndex + 1];
  }
  // Bare token fallback: must look like `v1.<uid>.<exp>.<sig>`, not a URL.
  return raw.contains('.') && !raw.contains('/') ? raw : null;
}

/// Token version this app understands. Kept in sync with
/// `functions/src/exchange/token.ts`'s `EXCHANGE_TOKEN_VERSION`.
const _tokenVersion = 'v1';

String? _extractUid(String token) {
  final parts = token.split('.');
  if (parts.length != 4 || parts[0] != _tokenVersion) {
    return null;
  }
  final uid = parts[1];
  return uid.isEmpty ? null : uid;
}
