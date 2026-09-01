import 'package:app/feature/exchange/data/exchange_code.dart';
import 'package:app/feature/exchange/data/exchange_code_redeem_handler.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Region Cloud Functions run in; matches `setGlobalOptions` in
/// `functions/src/index.ts`.
const _functionsRegion = 'asia-northeast1';

/// Provides access to the Firestore `users/{uid}/exchanges` subcollection.
final profileExchangeRepositoryProvider = Provider<ProfileExchangeRepository>(
  (ref) => FirestoreProfileExchangeRepository(),
);

/// The [FirebaseFunctions] client.
///
/// Emulator Suite routing is wired once in `FirebaseInitializer.ensureInitialized`
/// (`main()`), the same place Firestore and Auth are routed, rather than here.
final firebaseFunctionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: _functionsRegion),
);

/// Issues a signed [ExchangeToken] for the signed-in user via the
/// `issueExchangeToken` callable function.
abstract interface class ExchangeTokenIssuer {
  Future<ExchangeToken> issue();
}

final class CloudFunctionsExchangeTokenIssuer implements ExchangeTokenIssuer {
  const CloudFunctionsExchangeTokenIssuer(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<ExchangeToken> issue() async {
    final result = await _functions.httpsCallable('issueExchangeToken').call<Object?>();
    final data = result.data;
    final token = data is Map ? data['token'] : null;
    final expiresAt = data is Map ? data['expiresAt'] : null;
    if (token is! String || expiresAt is! num) {
      throw FormatException('issueExchangeToken returned an unexpected response: $data');
    }
    return ExchangeToken(
      value: token,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt.toInt() * 1000, isUtc: true),
    );
  }
}

final exchangeTokenIssuerProvider = Provider<ExchangeTokenIssuer>(
  (ref) => CloudFunctionsExchangeTokenIssuer(ref.watch(firebaseFunctionsProvider)),
);

final class CloudFunctionsExchangeCodeIssuer implements ExchangeCodeIssuer {
  const CloudFunctionsExchangeCodeIssuer(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<ExchangeCode> issue({bool rotate = false}) async {
    final result = await _functions.httpsCallable('issueExchangeCode').call<Object?>(<String, dynamic>{
      'rotate': rotate,
    });
    final data = result.data;
    final code = data is Map ? data['code'] : null;
    final expiresAt = data is Map ? data['expiresAt'] : null;
    if (code is! String || expiresAt is! num) {
      throw FormatException('issueExchangeCode returned an unexpected response: $data');
    }
    return ExchangeCode(
      value: code,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt.toInt() * 1000, isUtc: true),
    );
  }
}

final exchangeCodeIssuerProvider = Provider<ExchangeCodeIssuer>(
  (ref) => CloudFunctionsExchangeCodeIssuer(ref.watch(firebaseFunctionsProvider)),
);

final class CloudFunctionsExchangeCodeRedeemer implements ExchangeCodeRedeemer {
  const CloudFunctionsExchangeCodeRedeemer(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<ExchangeToken> redeem(String code) async {
    final result = await _functions.httpsCallable('redeemExchangeCode').call<Object?>(<String, dynamic>{
      'code': code,
    });
    final data = result.data;
    final token = data is Map ? data['token'] : null;
    final expiresAt = data is Map ? data['expiresAt'] : null;
    if (token is! String || expiresAt is! num) {
      throw FormatException('redeemExchangeCode returned an unexpected response: $data');
    }
    return ExchangeToken(
      value: token,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt.toInt() * 1000, isUtc: true),
    );
  }
}

final exchangeCodeRedeemerProvider = Provider<ExchangeCodeRedeemer>(
  (ref) => CloudFunctionsExchangeCodeRedeemer(ref.watch(firebaseFunctionsProvider)),
);
