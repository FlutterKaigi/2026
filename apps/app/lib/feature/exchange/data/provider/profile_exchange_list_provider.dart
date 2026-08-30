import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository_provider.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Emits the signed-in user's exchange list, most recent first, or an empty
/// list while signed out.
final profileExchangeListProvider = StreamProvider<List<ProfileExchange>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(profileExchangeRepositoryProvider).watchAll(user.uid);
});

/// The signed-in user's exchange count, via the `count()` aggregate query
/// (see issue-594.md section 8). Recomputed whenever the exchange list
/// changes so it stays in sync with additions/deletions made in this app.
final profileExchangeCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return 0;
  }
  // Triggers a recompute on every list change; the value itself is unused.
  ref.watch(profileExchangeListProvider);
  return ref.watch(profileExchangeRepositoryProvider).count(user.uid);
});
