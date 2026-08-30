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

  /// Arguments passed to [delete], in call order.
  final deleteCalls = <({String uid, String otherUid})>[];

  /// Arguments passed to [updateNote], in call order.
  final updateNoteCalls = <({String uid, String otherUid, String? note})>[];

  /// When set, the next [delete] throws this error once.
  Exception? nextDeleteError;

  /// When set, the next [updateNote] throws this error once.
  Exception? nextUpdateNoteError;

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

  @override
  Future<void> delete({required String uid, required String otherUid}) async {
    deleteCalls.add((uid: uid, otherUid: otherUid));
    final error = nextDeleteError;
    if (error != null) {
      nextDeleteError = null;
      throw error;
    }
    _exchangesByUid[uid]?.removeWhere((exchange) => exchange.id == otherUid);
    _controller.add(null);
  }

  @override
  Future<void> updateNote({required String uid, required String otherUid, required String? note}) async {
    updateNoteCalls.add((uid: uid, otherUid: otherUid, note: note));
    final error = nextUpdateNoteError;
    if (error != null) {
      nextUpdateNoteError = null;
      throw error;
    }
    final exchanges = _exchangesByUid[uid];
    if (exchanges == null) {
      return;
    }
    final index = exchanges.indexWhere((exchange) => exchange.id == otherUid);
    if (index == -1) {
      return;
    }
    exchanges[index] = exchanges[index].copyWith(note: note);
    _controller.add(null);
  }

  @override
  Future<int> countAll(String uid) async => _exchangesByUid[uid]?.length ?? 0;

  void dispose() {
    unawaited(_controller.close());
  }
}
