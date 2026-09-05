import 'dart:async';

import 'package:data/data.dart';

/// In-memory [ProfileExchangeRepository] for widget tests.
final class FakeProfileExchangeRepository implements ProfileExchangeRepository {
  FakeProfileExchangeRepository({Map<String, List<ProfileExchange>>? initialExchangesByUid})
    : _exchangesByUid = {
        for (final entry in (initialExchangesByUid ?? const {}).entries) entry.key: [...entry.value],
      };

  final Map<String, List<ProfileExchange>> _exchangesByUid;
  final _controller = StreamController<void>.broadcast();

  /// When set, the next [create] throws this error once.
  Exception? nextError;

  /// Arguments passed to [create], in call order.
  final createCalls = <({String uid, String otherUid, String token})>[];

  @override
  Stream<List<ProfileExchange>> watchAll(String uid) async* {
    yield List.unmodifiable(_exchangesByUid[uid] ?? const []);
    yield* _controller.stream.map((_) => List.unmodifiable(_exchangesByUid[uid] ?? const []));
  }

  @override
  Future<void> create({required String uid, required String otherUid, required String token}) async {
    createCalls.add((uid: uid, otherUid: otherUid, token: token));
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    final exchanges = _exchangesByUid.putIfAbsent(uid, () => []);
    exchanges.add(
      ProfileExchange(
        id: otherUid,
        createdAt: DateTime.now(),
        origin: ProfileExchangeOrigin.scan,
        token: token,
      ),
    );
    _controller.add(null);
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
