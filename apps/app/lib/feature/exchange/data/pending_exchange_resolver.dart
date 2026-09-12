import 'package:app/feature/exchange/data/exchange_scan_handler.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:data/data.dart';

/// Outcome of resolving a share-link token against the signed-in user,
/// covering the failure modes a scanned QR token cannot hit (a link can be
/// malformed, stale, or open the holder's own link) alongside the same
/// [CreateExchangeOutcome] a scan produces.
sealed class PendingExchangeResult {
  const PendingExchangeResult();
}

/// The token doesn't match the `v1.<uid>.<exp>.<sig>` / share-URL shape.
final class PendingExchangeInvalid extends PendingExchangeResult {
  const PendingExchangeInvalid();
}

/// The token's embedded expiry has already passed (see
/// [isExchangeTokenExpired]).
final class PendingExchangeExpired extends PendingExchangeResult {
  const PendingExchangeExpired();
}

/// The token embeds the signed-in user's own uid.
final class PendingExchangeSelf extends PendingExchangeResult {
  const PendingExchangeSelf();
}

/// The token was well-formed, unexpired, and not the user's own — [outcome]
/// is [ExchangeScanHandler.createExchange]'s result for it.
final class PendingExchangeResolved extends PendingExchangeResult {
  const PendingExchangeResolved(this.outcome);

  final CreateExchangeOutcome outcome;
}

/// Resolves a share-link token for [myUid], creating the exchange via the
/// same path a QR scan uses ([ExchangeScanHandler]) once the token has
/// cleared the checks a scan doesn't need (shape, expiry, self).
///
/// Re-checking shape and expiry here (not just wherever the token was first
/// read from the link) matters because a token queued in
/// `pendingExchangeTokenProvider` while the visitor signs in can go stale
/// before this runs.
Future<PendingExchangeResult> resolvePendingExchangeToken({
  required String token,
  required String myUid,
  required ProfileExchangeRepository repository,
}) async {
  final scanned = parseScannedExchangeToken(token);
  if (scanned == null) {
    return const PendingExchangeInvalid();
  }
  if (isExchangeTokenExpired(token)) {
    return const PendingExchangeExpired();
  }
  if (scanned.otherUid == myUid) {
    return const PendingExchangeSelf();
  }
  final outcome = await ExchangeScanHandler(
    myUid: myUid,
    repository: repository,
  ).createExchange(otherUid: scanned.otherUid, token: scanned.token);
  return PendingExchangeResolved(outcome);
}
