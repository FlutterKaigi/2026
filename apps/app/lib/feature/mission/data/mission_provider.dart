import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/mission/data/profile_exchange_progress.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:app/feature/sns_post/data/sns_post_provider.dart';
import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
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

/// Whether a mission is complete, or why that cannot be told yet.
enum MissionStatus {
  complete,
  incomplete,
  loading,
  error;

  static MissionStatus from<T>(AsyncValue<T> value, bool Function(T) isComplete) => switch (value) {
    AsyncData(:final value) => isComplete(value) ? complete : incomplete,
    AsyncError() => error,
    _ => loading,
  };
}

typedef MissionStatuses = ({MissionStatus supportLt, MissionStatus profileExchange, MissionStatus snsPost});

extension MissionStatusesSummary on MissionStatuses {
  /// Every mission's status, in display order.
  List<MissionStatus> get all => [supportLt, profileExchange, snsPost];

  int get completeCount => all.where((status) => status == MissionStatus.complete).length;

  /// The missions taken together. A failure, then a pending check, outranks
  /// the rest because the achieved count is not final until every mission is
  /// known.
  MissionStatus get overall {
    final statuses = all;
    if (statuses.contains(MissionStatus.error)) {
      return MissionStatus.error;
    }
    if (statuses.contains(MissionStatus.loading)) {
      return MissionStatus.loading;
    }
    return statuses.every((status) => status == MissionStatus.complete)
        ? MissionStatus.complete
        : MissionStatus.incomplete;
  }
}

/// What completes each mission, shared by the mission page and the venue
/// events hub so both count the same achievements.
final missionStatusesProvider = Provider.autoDispose.family<MissionStatuses, String>(
  (ref, uid) => (
    supportLt: MissionStatus.from(
      ref.watch(supportLtRegistrationProvider(uid)),
      (registration) => registration != null,
    ),
    profileExchange: MissionStatus.from(
      ref.watch(missionExchangeProgressProvider(uid)),
      (progress) => progress.isComplete,
    ),
    snsPost: MissionStatus.from(ref.watch(snsPostRegistrationProvider(uid)), (post) => post != null),
  ),
);
