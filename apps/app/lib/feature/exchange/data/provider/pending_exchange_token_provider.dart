import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A pending share-link token paired with the uid that was signed in (or
/// `null` if nobody was) the moment it was queued.
typedef PendingExchangeToken = ({String? uid, String token});

/// Holds a share-link (`/x/<token>`) token whose exchange couldn't be
/// created yet because the visitor wasn't signed in or hadn't created a
/// profile.
///
/// `ExchangeShareLinkPage` sets this when its `ExchangeAccessGate` doesn't
/// pass immediately, and the same page consumes it once the gate does pass —
/// so it is only ever left set here across a sign-in / profile-creation
/// detour. `AccountPage` watches it too and consumes it if it is still set
/// once the visitor lands back there signed in with a profile, which is how
/// the exchange still completes without the visitor returning to the
/// original link.
///
/// `ProviderScope` is created once at app launch and this state is not
/// disposed on sign-out, so without the recorded `uid` a token queued while
/// one account was signed in (waiting on a profile) could resolve under a
/// different account that signs in afterwards on the same device.
/// `AccountPage` checks that uid before consuming it, and
/// [clear] is called explicitly on sign-out and account deletion — the same
/// treatment `ExchangeTokenCacheRepository` / `ExchangeCodeCacheRepository`
/// get. A `null` recorded uid (queued while nobody was signed in) has no uid
/// to mismatch against and stays eligible for whichever uid signs in next,
/// which is how a signed-out visitor's link survives its own sign-in detour.
class PendingExchangeTokenNotifier extends Notifier<PendingExchangeToken?> {
  @override
  PendingExchangeToken? build() => null;

  void set(String? uid, String token) => state = (uid: uid, token: token);

  /// Clears the pending entry only if [token] is still the queued one — a
  /// consumer that finished handling an older value should never clobber a
  /// newer link opened in the meantime.
  ///
  /// The recorded uid is deliberately not part of that comparison. A consumer
  /// resolves under the uid signed in at resolve time, which need not be the
  /// one the entry was queued under: a token queued while nobody was signed
  /// in is resolved by whoever signs in during the detour. Requiring the two
  /// to match would leave the entry behind for the next consumer to redo an
  /// exchange that already went through. Only resolving is uid-sensitive —
  /// `AccountPage` discards a mismatched entry rather than resolving it —
  /// while dropping one is safe under any uid.
  void clearIfCurrent(String token) {
    if (state?.token == token) {
      state = null;
    }
  }

  /// Drops the pending entry unconditionally, regardless of which uid it was
  /// recorded under. Called on sign-out and account deletion.
  void clear() => state = null;
}

final pendingExchangeTokenProvider = NotifierProvider<PendingExchangeTokenNotifier, PendingExchangeToken?>(
  PendingExchangeTokenNotifier.new,
);
