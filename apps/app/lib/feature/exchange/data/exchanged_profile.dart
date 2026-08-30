import 'dart:async';

import 'package:data/data.dart';

/// One entry in the signed-in user's exchange list, joined with the other
/// attendee's profile.
class ExchangedProfile {
  const ExchangedProfile({required this.exchange, required this.profile});

  final ProfileExchange exchange;

  /// The other attendee's profile, or `null` once it has loaded and the
  /// attendee has deleted their profile (or their account).
  final UserProfile? profile;

  String get otherUid => exchange.id;
}

/// Joins the signed-in user's exchange list with each other attendee's
/// profile, keeping both live: entries are added/removed as [exchanges]
/// changes, and each profile keeps updating (including turning `null` if the
/// other attendee deletes their profile) via [profileFor].
///
/// An entry only appears once its profile subscription has emitted at least
/// once, so a newly-added exchange does not flash as "profile deleted" before
/// the first snapshot arrives.
Stream<List<ExchangedProfile>> watchExchangedProfiles({
  required Stream<List<ProfileExchange>> exchanges,
  required Stream<UserProfile?> Function(String uid) profileFor,
}) {
  late StreamController<List<ExchangedProfile>> controller;
  StreamSubscription<List<ProfileExchange>>? exchangesSubscription;
  final profileSubscriptions = <String, StreamSubscription<UserProfile?>>{};
  final profiles = <String, UserProfile?>{};
  final loadedUids = <String>{};
  var latestExchanges = const <ProfileExchange>[];

  void emit() {
    if (controller.isClosed) {
      return;
    }
    controller.add([
      for (final exchange in latestExchanges)
        if (loadedUids.contains(exchange.id)) ExchangedProfile(exchange: exchange, profile: profiles[exchange.id]),
    ]);
  }

  void syncProfileSubscriptions(List<ProfileExchange> exchangeList) {
    final wantedUids = exchangeList.map((exchange) => exchange.id).toSet();

    for (final uid in profileSubscriptions.keys.toList()) {
      if (!wantedUids.contains(uid)) {
        unawaited(profileSubscriptions.remove(uid)?.cancel());
        profiles.remove(uid);
        loadedUids.remove(uid);
      }
    }

    for (final uid in wantedUids) {
      if (profileSubscriptions.containsKey(uid)) {
        continue;
      }
      profileSubscriptions[uid] = profileFor(uid).listen(
        (profile) {
          profiles[uid] = profile;
          loadedUids.add(uid);
          emit();
        },
        onError: (Object _, StackTrace _) {
          // 相手プロフィールの取得エラーは「削除済み」として扱い、一覧全体は壊さない。
          profiles[uid] = null;
          loadedUids.add(uid);
          emit();
        },
      );
    }
  }

  controller = StreamController<List<ExchangedProfile>>.broadcast(
    onListen: () {
      exchangesSubscription = exchanges.listen(
        (list) {
          latestExchanges = list;
          syncProfileSubscriptions(list);
          emit();
        },
        onError: controller.addError,
      );
    },
    onCancel: () async {
      await exchangesSubscription?.cancel();
      for (final subscription in profileSubscriptions.values) {
        await subscription.cancel();
      }
      profileSubscriptions.clear();
      await controller.close();
    },
  );

  return controller.stream;
}
