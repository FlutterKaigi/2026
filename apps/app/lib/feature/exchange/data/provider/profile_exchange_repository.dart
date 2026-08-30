import 'package:app/core/provider/environment.dart';
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

/// The [FirebaseFunctions] client, routed to the local Emulator Suite on the
/// develop flavor (mirrors `apps/dashboard`'s `CollectionSyncService`).
final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  final environment = ref.watch(environmentProvider);
  final functions = FirebaseFunctions.instanceFor(region: _functionsRegion);
  if (environment.flavor == Flavor.develop) {
    final host = environment.firestoreHost.split(':').first;
    functions.useFunctionsEmulator(host, 5001);
  }
  return functions;
});

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
      throw FormatException('issueExchangeToken から不正なレスポンスを受け取りました: $data');
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
