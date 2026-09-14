import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/mission/data/profile_exchange_progress.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Account-keyed subscriptions prevent a previous account's cached progress
/// from being displayed during sign-in changes.
final missionExchangesProvider = StreamProvider.autoDispose.family<List<ProfileExchange>, String>(
  (ref, uid) => ref.watch(profileExchangeRepositoryProvider).watchAll(uid),
  retry: (_, _) => null,
);

final missionExchangeProgressProvider = Provider.autoDispose.family<AsyncValue<ProfileExchangeProgress>, String>(
  (ref, uid) {
    final profile = ref.watch(exchangedUserProfileProvider(uid));
    final exchanges = ref.watch(missionExchangesProvider(uid));
    if (profile.hasError) {
      return AsyncError(profile.error!, profile.stackTrace!);
    }
    if (exchanges.hasError) {
      return AsyncError(exchanges.error!, exchanges.stackTrace!);
    }
    if (profile.isLoading || exchanges.isLoading) {
      return const AsyncLoading();
    }
    final others = [
      // The exchange trigger clears scan tokens after verification. Pending
      // or rejected scans must not award a mission before that acknowledgement.
      for (final id
          in exchanges.requireValue
              .where((exchange) => exchange.origin == ProfileExchangeOrigin.mirror || exchange.token == null)
              .map((exchange) => exchange.id)
              .toSet())
        if (id != uid) ref.watch(exchangedUserProfileProvider(id)),
    ];
    for (final other in others) {
      if (other.hasError) {
        return AsyncError(other.error!, other.stackTrace!);
      }
    }
    if (others.any((other) => other.isLoading)) {
      return const AsyncLoading();
    }
    return AsyncData(
      ProfileExchangeProgress.evaluate(
        uid: uid,
        profile: profile.requireValue,
        exchangedProfiles: others.map((other) => other.requireValue),
      ),
    );
  },
);
