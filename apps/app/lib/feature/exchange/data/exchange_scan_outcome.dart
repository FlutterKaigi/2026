import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/exchange/data/exchange_link.dart';
import 'package:app/feature/exchange/data/exchange_write_timeout.dart';
import 'package:data/data.dart';
import 'package:firebase_core/firebase_core.dart';

/// Result of handling one scanned (or code-redeemed) exchange QR/token.
enum ExchangeScanOutcomeKind {
  /// The exchange was recorded in the signed-in user's list.
  success,

  /// The scanned code belongs to the signed-in user themself.
  selfScan,

  /// The scanned value is not a recognizable exchange QR/token.
  malformed,

  /// The token's claimed expiry has already passed. Checked client-side
  /// before writing anything; a tampered-but-unexpired token still reaches
  /// [ProfileExchangeRepository.createFromScan] and is only caught by the
  /// server-side signature check (see pr1-impl-notes.md).
  expired,

  /// This pair has already exchanged; the create was rejected by the
  /// Firestore rules (`permission-denied`) — see pr1-impl-notes.md.
  duplicate,

  /// The write was applied to the local cache (and is already visible in the
  /// signed-in user's list) but timed out waiting for the server to
  /// acknowledge it — most likely because the device is offline. It will
  /// finish syncing once connectivity returns.
  offlinePending,

  /// Any other failure (unexpected Firestore error, etc).
  error,
}

class ExchangeScanOutcome {
  const ExchangeScanOutcome(this.kind, {this.otherUid});

  final ExchangeScanOutcomeKind kind;

  /// uid of the other attendee, set for every kind except [ExchangeScanOutcomeKind.malformed].
  final String? otherUid;
}

/// Handles a scanned QR value (or a token obtained via a redeemed 6-digit
/// code) for [currentUid]: parses it, rejects obvious self-scans and expired
/// tokens, and records the exchange through [repository].
///
/// Kept independent of `MobileScanner` so it can be unit tested without a
/// camera. [raw] is the full scanned string when called from the scan page;
/// pass a bare `v1.<uid>.<exp>.<sig>` token here when called after
/// `redeemExchangeCode` (see [ScannedExchangeToken] format notes).
///
/// [now] and [timeout] are test-only injection points; production callers
/// should leave them at their defaults.
Future<ExchangeScanOutcome> handleScannedExchangeToken({
  required String raw,
  required String currentUid,
  required ProfileExchangeRepository repository,
  DateTime? now,
  Duration timeout = exchangeWriteTimeout,
}) async {
  final parsed = parseScannedExchangeToken(raw);
  if (parsed == null) {
    return const ExchangeScanOutcome(ExchangeScanOutcomeKind.malformed);
  }
  if (parsed.uid == currentUid) {
    return ExchangeScanOutcome(ExchangeScanOutcomeKind.selfScan, otherUid: parsed.uid);
  }
  if (!(now ?? DateTime.now()).toUtc().isBefore(parsed.expiresAt)) {
    return ExchangeScanOutcome(ExchangeScanOutcomeKind.expired, otherUid: parsed.uid);
  }

  try {
    await repository.createFromScan(uid: currentUid, otherUid: parsed.uid, token: parsed.token).timeout(timeout);
    return ExchangeScanOutcome(ExchangeScanOutcomeKind.success, otherUid: parsed.uid);
  } on TimeoutException {
    return ExchangeScanOutcome(ExchangeScanOutcomeKind.offlinePending, otherUid: parsed.uid);
  } on FirebaseException catch (exception) {
    if (exception.code == 'permission-denied') {
      return ExchangeScanOutcome(ExchangeScanOutcomeKind.duplicate, otherUid: parsed.uid);
    }
    return ExchangeScanOutcome(ExchangeScanOutcomeKind.error, otherUid: parsed.uid);
  }
}

/// Localized message for [outcome], shared by the scan page and the 6-digit
/// code entry flow so both report the same wording.
String exchangeScanOutcomeMessage(Translations t, ExchangeScanOutcome outcome) => switch (outcome.kind) {
  ExchangeScanOutcomeKind.success => t.exchange.scan.success,
  ExchangeScanOutcomeKind.selfScan => t.exchange.scan.selfScan,
  ExchangeScanOutcomeKind.malformed => t.exchange.scan.malformed,
  ExchangeScanOutcomeKind.expired => t.exchange.scan.expired,
  ExchangeScanOutcomeKind.duplicate => t.exchange.scan.duplicate,
  ExchangeScanOutcomeKind.offlinePending => t.exchange.scan.offlinePending,
  ExchangeScanOutcomeKind.error => t.exchange.scan.genericError,
};
