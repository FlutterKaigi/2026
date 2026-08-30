import 'dart:async';

import 'package:data/data.dart';
import 'package:firebase_core/firebase_core.dart';

/// In-memory [ProfileExchangeRepository] for widget tests.
final class FakeProfileExchangeRepository implements ProfileExchangeRepository {
  FakeProfileExchangeRepository({String uid = 'uid-1', List<ProfileExchange>? initialExchanges})
    : _exchangesByUid = {uid: List.of(initialExchanges ?? const [])};

  /// exchanges keyed by owner uid.
  final Map<String, List<ProfileExchange>> _exchangesByUid;
  final _controller = StreamController<void>.broadcast();

  /// When set, the next [createFromScan] throws this error once.
  Exception? nextCreateError;

  /// When set, [createFromScan] waits this long before completing (or
  /// throwing [nextCreateError]) — used to simulate a write stuck offline so
  /// callers can exercise their timeout handling without waiting for a real
  /// network hang.
  Duration? createFromScanDelay;

  /// otherUids passed to [delete], in call order.
  final deletedOtherUids = <String>[];

  /// Notes passed to [updateNote], in call order.
  final savedNotes = <String?>[];

  List<ProfileExchange> exchangesFor(String uid) => List.unmodifiable(_exchangesByUid[uid] ?? const []);

  @override
  Stream<List<ProfileExchange>> watchAll(String uid) async* {
    yield exchangesFor(uid);
    yield* _controller.stream.map((_) => exchangesFor(uid));
  }

  @override
  Future<void> createFromScan({required String uid, required String otherUid, required String token}) async {
    final delay = createFromScanDelay;
    if (delay != null) {
      await Future<void>.delayed(delay);
    }
    final error = nextCreateError;
    if (error != null) {
      nextCreateError = null;
      throw error;
    }
    final existing = _exchangesByUid.putIfAbsent(uid, () => []);
    if (existing.any((exchange) => exchange.id == otherUid)) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    }
    existing.add(
      ProfileExchange(id: otherUid, createdAt: DateTime.now(), origin: ProfileExchangeOrigin.scan, token: token),
    );
    _controller.add(null);
  }

  @override
  Future<void> updateNote({required String uid, required String otherUid, required String? note}) async {
    savedNotes.add(note);
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
  Future<void> delete({required String uid, required String otherUid}) async {
    deletedOtherUids.add(otherUid);
    _exchangesByUid[uid]?.removeWhere((exchange) => exchange.id == otherUid);
    _controller.add(null);
  }

  @override
  Future<int> count(String uid) async => exchangesFor(uid).length;

  void dispose() {
    unawaited(_controller.close());
  }
}
