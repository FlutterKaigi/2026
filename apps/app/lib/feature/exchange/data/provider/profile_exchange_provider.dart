import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the signed-in user's cached [ExchangeToken] so the QR code stays
/// displayable offline until it expires.
abstract interface class ExchangeTokenCacheRepository {
  ExchangeToken? read();

  Future<void> write(ExchangeToken token);
}

final class SharedPreferencesExchangeTokenCacheRepository implements ExchangeTokenCacheRepository {
  const SharedPreferencesExchangeTokenCacheRepository(this._preferences);

  static const _valueKey = 'exchange_token_value';
  static const _expiresAtKey = 'exchange_token_expires_at_millis';

  final SharedPreferences _preferences;

  @override
  ExchangeToken? read() {
    final value = _preferences.getString(_valueKey);
    final expiresAtMillis = _preferences.getInt(_expiresAtKey);
    if (value == null || expiresAtMillis == null) {
      return null;
    }
    return ExchangeToken(
      value: value,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMillis, isUtc: true),
    );
  }

  @override
  Future<void> write(ExchangeToken token) async {
    await _preferences.setString(_valueKey, token.value);
    await _preferences.setInt(_expiresAtKey, token.expiresAt.millisecondsSinceEpoch);
  }
}

final exchangeTokenCacheRepositoryProvider = Provider<ExchangeTokenCacheRepository>(
  (ref) => SharedPreferencesExchangeTokenCacheRepository(ref.watch(sharedPreferencesProvider)),
);

/// The signed-in user's own QR token: the cached value while still valid, or
/// a freshly issued one when missing or expired.
final myExchangeTokenProvider = AsyncNotifierProvider<MyExchangeTokenNotifier, ExchangeToken>(
  MyExchangeTokenNotifier.new,
);

class MyExchangeTokenNotifier extends AsyncNotifier<ExchangeToken> {
  @override
  Future<ExchangeToken> build() async {
    final cached = ref.watch(exchangeTokenCacheRepositoryProvider).read();
    if (cached != null && !cached.isExpired) {
      return cached;
    }
    return _issueAndCache();
  }

  /// Issues a fresh token even when a cached one is still valid.
  Future<void> refresh() async {
    state = const AsyncLoading<ExchangeToken>();
    state = await AsyncValue.guard(_issueAndCache);
  }

  Future<ExchangeToken> _issueAndCache() async {
    final token = await ref.read(exchangeTokenIssuerProvider).issue();
    await ref.read(exchangeTokenCacheRepositoryProvider).write(token);
    return token;
  }
}

/// Emits the signed-in user's exchange list, most recently exchanged first,
/// or an empty list while signed out.
final exchangeListProvider = StreamProvider<List<ProfileExchange>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return switch (authState) {
    AsyncData(:final value) =>
      value == null
          ? Stream.value(const <ProfileExchange>[])
          : ref.watch(profileExchangeRepositoryProvider).watchAll(value.uid),
    AsyncError(:final error, :final stackTrace) => Stream<List<ProfileExchange>>.error(error, stackTrace),
    _ => const Stream<List<ProfileExchange>>.empty(),
  };
});

/// Joins one exchange list entry to the other attendee's [UserProfile].
final exchangedUserProfileProvider = StreamProvider.family<UserProfile?, String>(
  (ref, otherUid) => ref.watch(userProfileRepositoryProvider).watch(otherUid),
);
