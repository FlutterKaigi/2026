import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/provider/exchange_token_cache_repository.dart';
import 'package:app/feature/exchange/data/provider/exchange_token_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The signed-in user's own exchange QR token, ready to render.
class ExchangeQrToken {
  const ExchangeQrToken({required this.token, required this.expiresAt, required this.isCached});

  final String token;
  final DateTime expiresAt;

  /// `true` when [token] came from the local cache (network call failed),
  /// i.e. the QR is being shown offline — see issue-594.md section 4.
  final bool isCached;
}

/// Issues (or falls back to a cached) QR token for the signed-in user.
///
/// Mirrors `userProfileProvider`: re-fetches whenever the signed-in user
/// changes.
final exchangeQrTokenProvider = AsyncNotifierProvider<ExchangeQrTokenNotifier, ExchangeQrToken>(
  ExchangeQrTokenNotifier.new,
);

class ExchangeQrTokenNotifier extends AsyncNotifier<ExchangeQrToken> {
  @override
  Future<ExchangeQrToken> build() async {
    final user = ref.watch(authStateChangesProvider).value;
    if (user == null) {
      // Rebuilds once signed in; the home page only reads this while signed in.
      return Future<ExchangeQrToken>.error(StateError('signed out'));
    }
    return _fetch(user.uid);
  }

  /// Re-issues a fresh token, ignoring any cached fallback.
  Future<void> refresh() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      return;
    }
    state = const AsyncLoading<ExchangeQrToken>();
    state = await AsyncValue.guard(() => _fetch(user.uid));
  }

  Future<ExchangeQrToken> _fetch(String uid) async {
    final cacheRepository = ref.read(exchangeTokenCacheRepositoryProvider);
    try {
      final issued = await ref.read(exchangeTokenServiceProvider).issueToken();
      final expiresAt = DateTime.now().add(Duration(seconds: issued.expiresInSeconds));
      await cacheRepository.write(
        uid,
        CachedExchangeToken(token: issued.token, expiresAtMillis: expiresAt.millisecondsSinceEpoch),
      );
      return ExchangeQrToken(token: issued.token, expiresAt: expiresAt, isCached: false);
    } on Exception {
      final cached = cacheRepository.read(uid);
      if (cached != null && !cached.isExpired) {
        return ExchangeQrToken(
          token: cached.token,
          expiresAt: DateTime.fromMillisecondsSinceEpoch(cached.expiresAtMillis),
          isCached: true,
        );
      }
      rethrow;
    }
  }
}
