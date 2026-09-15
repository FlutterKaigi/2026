import 'dart:async';

import 'package:data/data.dart';

final class FakeSnsPostRepository implements SnsPostRepository {
  final registrations = <String, SnsPostRegistration>{};
  final watchedUids = <String>[];
  final saves = <({String uid, String url, SnsPostCompanion companion})>[];
  final _controller = StreamController<void>.broadcast();
  Exception? saveError;
  Exception? watchError;
  Completer<void>? saveGate;

  @override
  Stream<SnsPostRegistration?> watch(String uid) {
    watchedUids.add(uid);
    if (watchError case final error?) {
      return Stream.error(error);
    }
    return Stream.multi((listener) {
      final subscription = _controller.stream.listen(
        (_) => listener.add(registrations[uid]),
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = subscription.cancel;
      listener.add(registrations[uid]);
    });
  }

  @override
  Future<void> save({required String uid, required String url, required SnsPostCompanion companion}) async {
    saves.add((uid: uid, url: url, companion: companion));
    await saveGate?.future;
    if (saveError case final error?) {
      throw error;
    }
    registrations[uid] = SnsPostRegistration(url: url, companion: companion, updatedAt: DateTime.utc(2026, 11, 13));
    _controller.add(null);
  }

  void dispose() => unawaited(_controller.close());
}
