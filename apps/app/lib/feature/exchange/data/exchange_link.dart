/// Host used for the profile-exchange QR payload.
///
/// Kept as a plain URL (rather than the bare token) so it doubles as a
/// shareable link once Universal Links / App Links are wired up (see
/// issue-594.md section 5). The app itself never opens this URL; it only
/// builds it for the QR code and parses it back out of a scanned barcode.
const exchangeLinkOrigin = 'https://2026.flutterkaigi.jp';

/// Host that a scanned exchange link must match. Computed once from
/// [exchangeLinkOrigin] so a scanned QR for an unrelated site (which may
/// still happen to contain an `/x/<something>` path) is never treated as an
/// exchange link.
final _exchangeLinkHost = Uri.parse(exchangeLinkOrigin).host;

/// Builds the QR payload for [token]: `https://2026.flutterkaigi.jp/x/<token>`.
Uri buildExchangeQrUri(String token) => Uri.parse('$exchangeLinkOrigin/x/$token');

/// A signed exchange token extracted from a scanned QR code, plus the uid it
/// claims to belong to and the expiry it claims.
///
/// [uid] and [expiresAt] are read directly off the unverified token
/// (`v1.<uid>.<exp>.<sig>`) for client-side checks only (self-scan detection,
/// an early expiry check, routing). The signature is verified server-side by
/// the `onProfileExchangeCreated` Cloud Function trigger; this class does not
/// and cannot verify it since the signing secret never reaches the client —
/// so [expiresAt] alone is not proof the token is genuine, only a basis for
/// rejecting an obviously-expired one before writing anything.
class ScannedExchangeToken {
  const ScannedExchangeToken({required this.token, required this.uid, required this.expiresAt});

  final String token;
  final String uid;
  final DateTime expiresAt;
}

/// Parses a scanned barcode value into a [ScannedExchangeToken].
///
/// Accepts the `https://<host>/x/<token>` link format described in
/// issue-594.md section 4 (only for [exchangeLinkOrigin]'s host, over
/// `https`), and — defensively — a bare `v1.<uid>.<exp>.<sig>` token in case
/// a QR was generated without the URL wrapper. Returns `null` when [raw]
/// does not look like either shape, or the token itself is malformed (wrong
/// version, missing uid, non-numeric expiry); this is a best-effort format
/// check only, not a signature check.
ScannedExchangeToken? parseScannedExchangeToken(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final token = _extractToken(trimmed);
  if (token == null) {
    return null;
  }

  return _parseToken(token);
}

String? _extractToken(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) {
    // 他サイトの QR コード（たまたま `/x/...` というパスを持つだけのもの）を
    // 交換リンクと誤認しないよう、スキームとホストも一致させる。
    if (uri.scheme != 'https' || uri.host != _exchangeLinkHost) {
      return null;
    }
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

ScannedExchangeToken? _parseToken(String token) {
  final parts = token.split('.');
  if (parts.length != 4 || parts[0] != _tokenVersion) {
    return null;
  }
  final uid = parts[1];
  if (uid.isEmpty) {
    return null;
  }
  final expSeconds = int.tryParse(parts[2]);
  if (expSeconds == null) {
    return null;
  }
  return ScannedExchangeToken(
    token: token,
    uid: uid,
    expiresAt: DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000, isUtc: true),
  );
}
