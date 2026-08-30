import 'package:hooks_riverpod/hooks_riverpod.dart';

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
class PendingExchangeTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String token) => state = token;

  /// Clears [token] only if it is still the pending one — a consumer that
  /// finished handling an older value should never clobber a newer link
  /// opened in the meantime.
  void clearIfCurrent(String token) {
    if (state == token) {
      state = null;
    }
  }
}

final pendingExchangeTokenProvider = NotifierProvider<PendingExchangeTokenNotifier, String?>(
  PendingExchangeTokenNotifier.new,
);
