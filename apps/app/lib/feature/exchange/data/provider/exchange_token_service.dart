import 'package:app/feature/exchange/data/provider/exchange_functions_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final exchangeTokenServiceProvider = Provider<ExchangeTokenService>(
  (ref) => CloudFunctionsExchangeTokenService(ref.watch(exchangeFunctionsProvider)),
);

/// A signed exchange token issued for the signed-in user's own QR code.
class IssuedExchangeToken {
  const IssuedExchangeToken({required this.token, required this.expiresInSeconds});

  final String token;
  final int expiresInSeconds;
}

/// A 6-digit fallback code issued for the signed-in user.
class IssuedExchangeCode {
  const IssuedExchangeCode({required this.code, required this.expiresInSeconds});

  final String code;
  final int expiresInSeconds;
}

/// The exchange token behind a redeemed 6-digit code, plus the issuer's uid.
class RedeemedExchangeCode {
  const RedeemedExchangeCode({required this.uid, required this.token});

  final String uid;
  final String token;
}

/// Wraps the `issueExchangeToken` / `issueExchangeCode` / `redeemExchangeCode`
/// callables (see `functions/src/exchange/callable.ts`).
///
/// Callers should catch [FirebaseFunctionsException] for user-facing errors
/// (e.g. `not-found`, `deadline-exceeded`, `failed-precondition`,
/// `resource-exhausted` from `redeemExchangeCode`).
abstract interface class ExchangeTokenService {
  /// Issues a signed token for the signed-in user's own QR code. Valid for
  /// 24 hours.
  Future<IssuedExchangeToken> issueToken();

  /// Issues a 6-digit fallback code for the signed-in user. Valid for 5
  /// minutes.
  Future<IssuedExchangeCode> issueCode();

  /// Redeems [code], returning the issuer's uid and a signed token that can
  /// be recorded exactly like a scanned QR token
  /// (`ProfileExchangeRepository.createFromScan`).
  Future<RedeemedExchangeCode> redeemCode(String code);
}

final class CloudFunctionsExchangeTokenService implements ExchangeTokenService {
  const CloudFunctionsExchangeTokenService(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<IssuedExchangeToken> issueToken() async {
    final result = await _functions.httpsCallable('issueExchangeToken').call<Object?>();
    final data = _asMap(result.data);
    return IssuedExchangeToken(
      token: data['token'] as String,
      expiresInSeconds: (data['expiresInSeconds'] as num).toInt(),
    );
  }

  @override
  Future<IssuedExchangeCode> issueCode() async {
    final result = await _functions.httpsCallable('issueExchangeCode').call<Object?>();
    final data = _asMap(result.data);
    return IssuedExchangeCode(
      code: data['code'] as String,
      expiresInSeconds: (data['expiresInSeconds'] as num).toInt(),
    );
  }

  @override
  Future<RedeemedExchangeCode> redeemCode(String code) async {
    final result = await _functions.httpsCallable('redeemExchangeCode').call<Object?>({'code': code});
    final data = _asMap(result.data);
    return RedeemedExchangeCode(uid: data['uid'] as String, token: data['token'] as String);
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw StateError('Unexpected callable response: $data');
  }
}
