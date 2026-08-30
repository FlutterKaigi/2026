import 'dart:convert';

import 'package:app/core/provider/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final exchangeTokenCacheRepositoryProvider = Provider<ExchangeTokenCacheRepository>(
  (ref) => SharedPreferencesExchangeTokenCacheRepository(ref.watch(sharedPreferencesProvider)),
);

/// A cached QR token for one uid, as returned by `issueExchangeToken`.
class CachedExchangeToken {
  const CachedExchangeToken({required this.token, required this.expiresAtMillis});

  factory CachedExchangeToken.fromJson(Map<String, dynamic> json) => CachedExchangeToken(
    token: json['token'] as String,
    expiresAtMillis: (json['expiresAtMillis'] as num).toInt(),
  );

  final String token;
  final int expiresAtMillis;

  bool get isExpired => DateTime.now().millisecondsSinceEpoch >= expiresAtMillis;

  Map<String, dynamic> toJson() => {'token': token, 'expiresAtMillis': expiresAtMillis};
}

/// Persists the signed-in user's own QR token locally, so the QR code can
/// still be shown (until it expires) while offline — see issue-594.md
/// section 4.
abstract interface class ExchangeTokenCacheRepository {
  /// Returns the token cached for [uid], or `null` if none was cached.
  CachedExchangeToken? read(String uid);

  Future<void> write(String uid, CachedExchangeToken token);
}

final class SharedPreferencesExchangeTokenCacheRepository implements ExchangeTokenCacheRepository {
  const SharedPreferencesExchangeTokenCacheRepository(this._preferences);

  final SharedPreferences _preferences;

  static String _key(String uid) => 'exchange_token_cache_$uid';

  @override
  CachedExchangeToken? read(String uid) {
    final raw = _preferences.getString(_key(uid));
    if (raw == null) {
      return null;
    }
    try {
      return CachedExchangeToken.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(String uid, CachedExchangeToken token) => _preferences.setString(
    _key(uid),
    jsonEncode(token.toJson()),
  );
}
