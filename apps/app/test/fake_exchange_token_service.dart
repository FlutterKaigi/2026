import 'package:app/feature/exchange/data/provider/exchange_token_service.dart';
import 'package:firebase_core/firebase_core.dart';

/// In-memory [ExchangeTokenService] for widget tests.
final class FakeExchangeTokenService implements ExchangeTokenService {
  FakeExchangeTokenService({this.tokenToIssue = 'v1.other-uid.9999999999.sig', this.codeToIssue = '123456'});

  final String tokenToIssue;
  final String codeToIssue;

  /// While set, every [issueToken] call throws this error (persistent, not
  /// single-use — `AsyncNotifier.build()` can run more than once for the
  /// same watched state, so a one-shot error could be silently consumed by
  /// an extra internal call before the widget under test ever reads it).
  Exception? issueTokenError;

  /// When set, the next [redeemCode] throws this error once.
  Exception? nextRedeemError;

  /// Codes passed to [redeemCode], in call order.
  final redeemedCodes = <String>[];

  /// uid returned by [redeemCode] on success.
  String redeemedUid = 'other-uid';

  int issueTokenCallCount = 0;
  int issueCodeCallCount = 0;

  @override
  Future<IssuedExchangeToken> issueToken() async {
    issueTokenCallCount++;
    final error = issueTokenError;
    if (error != null) {
      throw error;
    }
    return IssuedExchangeToken(token: tokenToIssue, expiresInSeconds: 24 * 60 * 60);
  }

  @override
  Future<IssuedExchangeCode> issueCode() async {
    issueCodeCallCount++;
    return IssuedExchangeCode(code: codeToIssue, expiresInSeconds: 5 * 60);
  }

  @override
  Future<RedeemedExchangeCode> redeemCode(String code) async {
    redeemedCodes.add(code);
    final error = nextRedeemError;
    if (error != null) {
      nextRedeemError = null;
      throw error;
    }
    return RedeemedExchangeCode(uid: redeemedUid, token: 'v1.$redeemedUid.9999999999.sig');
  }
}

/// A [FirebaseException] shaped like `redeemExchangeCode`'s errors, for tests.
///
/// The real SDK throws `FirebaseFunctionsException` (a [FirebaseException]
/// subtype with a protected constructor); production code catches the base
/// type, so a plain [FirebaseException] with the same `code` is
/// indistinguishable to it.
FirebaseException fakeFunctionsException(String code) =>
    FirebaseException(plugin: 'firebase_functions', code: code, message: code);
