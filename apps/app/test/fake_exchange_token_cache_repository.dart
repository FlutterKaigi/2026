import 'package:app/feature/exchange/data/provider/exchange_token_cache_repository.dart';

/// In-memory [ExchangeTokenCacheRepository] for widget tests.
final class FakeExchangeTokenCacheRepository implements ExchangeTokenCacheRepository {
  final _cache = <String, CachedExchangeToken>{};

  @override
  CachedExchangeToken? read(String uid) => _cache[uid];

  @override
  Future<void> write(String uid, CachedExchangeToken token) async {
    _cache[uid] = token;
  }
}
