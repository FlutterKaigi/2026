import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/exchange_code.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the signed-in user's cached [ExchangeToken] so the QR code stays
/// displayable offline until it expires.
///
/// Every entry point is keyed by uid: SharedPreferences is device-scoped, not
/// account-scoped, so a uid-less key would let a token issued for one signed-in
/// user survive into another user's session on the same device.
abstract interface class ExchangeTokenCacheRepository {
  ExchangeToken? read(String uid);

  Future<void> write(String uid, ExchangeToken token);

  /// Removes any cached token for [uid]. Called on sign-out and account
  /// deletion so a stale token never lingers under a uid nobody is signed in
  /// as.
  Future<void> clear(String uid);
}

final class SharedPreferencesExchangeTokenCacheRepository implements ExchangeTokenCacheRepository {
  const SharedPreferencesExchangeTokenCacheRepository(this._preferences);

  final SharedPreferences _preferences;

  static String _valueKey(String uid) => 'exchange_token_value_$uid';
  static String _expiresAtKey(String uid) => 'exchange_token_expires_at_millis_$uid';

  @override
  ExchangeToken? read(String uid) {
    final value = _preferences.getString(_valueKey(uid));
    final expiresAtMillis = _preferences.getInt(_expiresAtKey(uid));
    if (value == null || expiresAtMillis == null) {
      return null;
    }
    return ExchangeToken(
      value: value,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMillis, isUtc: true),
    );
  }

  @override
  Future<void> write(String uid, ExchangeToken token) async {
    await _preferences.setString(_valueKey(uid), token.value);
    await _preferences.setInt(_expiresAtKey(uid), token.expiresAt.millisecondsSinceEpoch);
  }

  @override
  Future<void> clear(String uid) async {
    await _preferences.remove(_valueKey(uid));
    await _preferences.remove(_expiresAtKey(uid));
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
    // Watched (not read) so signing out or switching accounts re-runs build()
    // and looks up the new uid's cache entry instead of reusing whatever the
    // previous user's token happened to be.
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    if (uid == null) {
      // This provider is only watched once ExchangeHomePage has confirmed a
      // signed-in user with a profile; reaching build() without one means
      // sign-out raced the widget teardown.
      throw StateError('myExchangeTokenProvider requires a signed-in user.');
    }
    final cached = ref.watch(exchangeTokenCacheRepositoryProvider).read(uid);
    if (cached != null && !cached.isExpired) {
      return cached;
    }
    return _issueAndCache(uid);
  }

  /// Issues a fresh token even when a cached one is still valid.
  Future<void> refresh() async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) {
      return;
    }
    state = const AsyncLoading<ExchangeToken>();
    state = await AsyncValue.guard(() => _issueAndCache(uid));
  }

  Future<ExchangeToken> _issueAndCache(String uid) async {
    final token = await ref.read(exchangeTokenIssuerProvider).issue();
    await ref.read(exchangeTokenCacheRepositoryProvider).write(uid, token);
    return token;
  }
}

/// The signed-in user's own 6-digit code: the QR fallback for camera-denied
/// or otherwise QR-incapable devices.
///
/// Unlike [myExchangeTokenProvider] this is never persisted and is
/// `autoDispose` — the code is short-lived (5 minutes server-side) by
/// design, so there is nothing worth caching across app restarts, and
/// leaving the exchange home screen and coming back later should issue a
/// fresh one rather than keep showing one that may already be invalid.
final myExchangeCodeProvider = AsyncNotifierProvider.autoDispose<MyExchangeCodeNotifier, ExchangeCode>(
  MyExchangeCodeNotifier.new,
);

class MyExchangeCodeNotifier extends AsyncNotifier<ExchangeCode> {
  @override
  Future<ExchangeCode> build() async {
    // Watched (not read) so signing out or switching accounts re-runs build()
    // instead of leaving the previous user's code state in place.
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    if (uid == null) {
      // This provider is only watched once ExchangeHomePage has confirmed a
      // signed-in user with a profile; reaching build() without one means
      // sign-out raced the widget teardown.
      throw StateError('myExchangeCodeProvider requires a signed-in user.');
    }
    return ref.read(exchangeCodeIssuerProvider).issue();
  }

  /// Issues a fresh code, replacing the current one (e.g. once it expires).
  Future<void> refresh() async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) {
      return;
    }
    state = const AsyncLoading<ExchangeCode>();
    state = await AsyncValue.guard(() => ref.read(exchangeCodeIssuerProvider).issue());
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
///
/// autoDispose: the exchange list can scroll through many other attendees in
/// a session, and without it every `otherUid` ever shown would keep its
/// Firestore snapshot listener alive for the rest of the app session.
final exchangedUserProfileProvider = StreamProvider.autoDispose.family<UserProfile?, String>(
  (ref, otherUid) => ref.watch(userProfileRepositoryProvider).watch(otherUid),
);
