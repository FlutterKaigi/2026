import 'dart:async';

import 'package:data/data.dart';

/// In-memory [UserProfileRepository] for widget tests.
final class FakeUserProfileRepository implements UserProfileRepository {
  FakeUserProfileRepository({UserProfile? initialProfile})
    : _profiles = {if (initialProfile != null) initialProfile.id: initialProfile};

  final Map<String, UserProfile> _profiles;
  final _controller = StreamController<void>.broadcast();

  /// When set, the next [save] or [delete] throws this error once.
  Exception? nextError;

  /// Profiles passed to [save], in call order.
  final savedProfiles = <UserProfile>[];

  /// Uids passed to [delete], in call order.
  final deletedUids = <String>[];

  /// Whether [watch] should emit its current value immediately.
  bool emitsInitialValue = true;

  UserProfile? profileFor(String uid) => _profiles[uid];

  @override
  Stream<UserProfile?> watch(String uid) async* {
    if (emitsInitialValue) {
      yield _profiles[uid];
    }
    yield* _controller.stream.map((_) => _profiles[uid]);
  }

  @override
  Future<void> save(UserProfile profile) async {
    _throwIfConfigured();
    savedProfiles.add(profile);
    _profiles[profile.id] = profile;
    _controller.add(null);
  }

  @override
  Future<void> delete(String uid) async {
    _throwIfConfigured();
    deletedUids.add(uid);
    _profiles.remove(uid);
    _controller.add(null);
  }

  void dispose() {
    unawaited(_controller.close());
  }

  void _throwIfConfigured() {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }
}
