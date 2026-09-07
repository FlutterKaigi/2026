import 'package:app/feature/exchange/data/exchange_code.dart';
import 'package:app/feature/exchange/data/exchange_scan_handler.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';

/// Outcome of redeeming a 6-digit code entered on the exchange home screen.
sealed class RedeemExchangeCodeOutcome {
  const RedeemExchangeCodeOutcome();
}

/// The exchange was created in the signed-in user's list.
final class RedeemExchangeCodeSucceeded extends RedeemExchangeCodeOutcome {
  const RedeemExchangeCodeSucceeded();
}

/// The other attendee is already in the signed-in user's exchange list.
final class RedeemExchangeCodeAlreadyExists extends RedeemExchangeCodeOutcome {
  const RedeemExchangeCodeAlreadyExists();
}

/// The code does not exist, is malformed, or has expired.
final class RedeemExchangeCodeInvalid extends RedeemExchangeCodeOutcome {
  const RedeemExchangeCodeInvalid();
}

/// The entered code is the caller's own.
final class RedeemExchangeCodeSelf extends RedeemExchangeCodeOutcome {
  const RedeemExchangeCodeSelf();
}

/// Too many failed attempts; `redeemExchangeCode` is temporarily rejecting
/// calls from this uid.
final class RedeemExchangeCodeRateLimited extends RedeemExchangeCodeOutcome {
  const RedeemExchangeCodeRateLimited();
}

/// Redeeming failed for a reason other than the above.
final class RedeemExchangeCodeFailed extends RedeemExchangeCodeOutcome {
  const RedeemExchangeCodeFailed(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

/// Redeems a 6-digit code via the `redeemExchangeCode` callable function,
/// then feeds the signed token it returns into [ExchangeScanHandler] — the
/// same `users/{me}/exchanges/{otherUid}` create() path a QR scan uses, so
/// the code fallback has no separate way of creating an exchange.
final class ExchangeCodeRedeemHandler {
  const ExchangeCodeRedeemHandler({
    required this.myUid,
    required this.redeemer,
    required this.repository,
  });

  final String myUid;
  final ExchangeCodeRedeemer redeemer;
  final ProfileExchangeRepository repository;

  Future<RedeemExchangeCodeOutcome> redeem(String code) async {
    final ExchangeToken token;
    try {
      token = await redeemer.redeem(code);
    } on FirebaseFunctionsException catch (exception) {
      return switch (exception.code) {
        'not-found' || 'invalid-argument' => const RedeemExchangeCodeInvalid(),
        'failed-precondition' => const RedeemExchangeCodeSelf(),
        'resource-exhausted' => const RedeemExchangeCodeRateLimited(),
        _ => RedeemExchangeCodeFailed(exception, StackTrace.current),
      };
    } on Exception catch (exception, stackTrace) {
      return RedeemExchangeCodeFailed(exception, stackTrace);
    }

    final scanned = parseScannedExchangeToken(token.value);
    if (scanned == null) {
      return RedeemExchangeCodeFailed(
        FormatException('redeemExchangeCode returned an unparsable token: ${token.value}'),
        StackTrace.current,
      );
    }

    final outcome = await ExchangeScanHandler(
      myUid: myUid,
      repository: repository,
    ).createExchange(otherUid: scanned.otherUid, token: scanned.token);
    return switch (outcome) {
      ExchangeCreated() => const RedeemExchangeCodeSucceeded(),
      ExchangeAlreadyExists() => const RedeemExchangeCodeAlreadyExists(),
      ExchangeCreateFailed(:final error, :final stackTrace) => RedeemExchangeCodeFailed(error, stackTrace),
    };
  }
}

/// Returns the signed-in user's live [ExchangeCode] via the
/// `issueExchangeCode` callable function, issuing one when they have none.
///
/// `rotate: true` asks for a brand-new code instead, invalidating the current
/// one server-side — the explicit reissue action, not something to do on a
/// plain screen visit.
abstract interface class ExchangeCodeIssuer {
  Future<ExchangeCode> issue({bool rotate = false});
}

/// Redeems another attendee's [ExchangeCode] via the `redeemExchangeCode`
/// callable function, returning a signed [ExchangeToken] for their uid.
abstract interface class ExchangeCodeRedeemer {
  Future<ExchangeToken> redeem(String code);
}
