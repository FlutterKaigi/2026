import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/mission/data/profile_exchange_progress.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Account-keyed subscriptions prevent a previous account's cached progress
/// from being displayed during sign-in changes.
final missionExchangesProvider = StreamProvider.autoDispose.family<List<ProfileExchange>, String>(
  (ref, uid) => ref.watch(profileExchangeRepositoryProvider).watchAll(uid),
  retry: (_, _) => null,
);

final missionExchangedProfilesProvider = StreamProvider.autoDispose.family<List<UserProfile>, String>(
  (ref, uid) {
    final exchanges = ref.watch(missionExchangesProvider(uid));
    return switch (exchanges) {
      AsyncData(:final value) => ref.watch(userProfileRepositoryProvider).watchMany({
        // Scan tokens are cleared only after the server verifies the exchange.
        for (final exchange in value)
          if (exchange.id != uid && (exchange.origin == ProfileExchangeOrigin.mirror || exchange.token == null))
            exchange.id,
      }),
      AsyncError(:final error, :final stackTrace) => Stream.error(error, stackTrace),
      _ => const Stream.empty(),
    };
  },
  retry: (_, _) => null,
);

final missionExchangeProgressProvider = Provider.autoDispose.family<AsyncValue<ProfileExchangeProgress>, String>(
  (ref, uid) {
    final profile = ref.watch(exchangedUserProfileProvider(uid));
    final others = ref.watch(missionExchangedProfilesProvider(uid));
    if (profile.hasError) {
      return AsyncError(profile.error!, profile.stackTrace!);
    }
    if (others.hasError) {
      return AsyncError(others.error!, others.stackTrace!);
    }
    if (profile.isLoading || others.isLoading) {
      return const AsyncLoading();
    }
    return AsyncData(
      ProfileExchangeProgress.evaluate(
        uid: uid,
        profile: profile.requireValue,
        exchangedProfiles: others.requireValue,
      ),
    );
  },
);
