import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/exchanged_profile.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository_provider.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The signed-in user's exchange list, joined with each other attendee's
/// `UserProfile` (see [watchExchangedProfiles]).
final exchangedProfileListProvider = StreamProvider<List<ExchangedProfile>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream.value(const []);
  }
  final exchangeRepository = ref.watch(profileExchangeRepositoryProvider);
  final profileRepository = ref.watch(userProfileRepositoryProvider);
  return watchExchangedProfiles(
    exchanges: exchangeRepository.watchAll(user.uid),
    profileFor: profileRepository.watch,
  );
});
