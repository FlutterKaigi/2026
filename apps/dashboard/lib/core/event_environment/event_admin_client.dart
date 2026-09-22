import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/core/env.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef EventAdminRequest = Future<Map<String, dynamic>> Function(Map<String, dynamic> request);

final eventAdminClientProvider = Provider<EventAdminClient?>((_) => null);
final eventAdminSnapshotProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(eventAdminClientProvider)?.watch() ?? const Stream.empty();
});

final eventAdminRequestProvider = Provider<EventAdminRequest>((_) {
  final callable = FirebaseFunctions.instanceFor(region: 'asia-northeast1').httpsCallable(
    'eventAdministration',
    options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
  );
  return (request) async => (await callable.call<Map<String, dynamic>>(request)).data;
});

/// One immutable environment/view per mounted page, using the dashboard login.
/// A single shared snapshot refreshes the whole page every two seconds.
class EventAdminClient {
  EventAdminClient({
    required this.environment,
    required Map<String, dynamic> view,
    required EventAdminRequest request,
    this.pollInterval = const Duration(seconds: 2),
  }) : _view = Map.unmodifiable(view),
       _request = request {
    _updates = StreamController<Map<String, dynamic>>.broadcast(onListen: _start, onCancel: _stop);
  }

  final Flavor environment;
  final Map<String, dynamic> _view;
  final EventAdminRequest _request;
  final Duration pollInterval;
  late final StreamController<Map<String, dynamic>> _updates;
  Timer? _timer;
  Map<String, dynamic>? _latest;
  String? _fingerprint;
  bool _disposed = false;
  bool _active = true;
  bool _reading = false;
  bool _refreshAgain = false;
  int _revision = 0;

  Stream<Map<String, dynamic>> watch() => Stream.multi((sink) {
    final subscription = _updates.stream.listen(sink.add, onError: sink.addError);
    if (_latest case final data?) sink.add(data);
    sink.onCancel = subscription.cancel;
  });

  void _start() {
    if (!_active || _disposed) return;
    _timer?.cancel();
    unawaited(refresh());
    _timer = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
  }

  void setActive(bool active) {
    if (_active == active || _disposed) return;
    _active = active;
    if (active && _updates.hasListener) {
      _start();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _latest = null;
    _fingerprint = null;
  }

  Future<Map<String, dynamic>> call(String action, [Map<String, dynamic> payload = const {}]) {
    if (_disposed) throw StateError('操作画面が閉じられました。');
    return _request({'environment': environment.name, 'action': action, 'payload': payload});
  }

  Future<Map<String, dynamic>> mutate(String action, Map<String, dynamic> payload) async {
    try {
      return await call(action, payload);
    } finally {
      // An ambiguous network response may already have committed. Re-read the
      // server before displaying a previous snapshot or offering another action.
      _revision++;
      if (!_disposed) unawaited(refresh());
    }
  }

  Future<void> refresh() async {
    if (_disposed || !_active || !_updates.hasListener) return;
    if (_reading) {
      _refreshAgain = true;
      return;
    }
    _reading = true;
    final revision = _revision;
    try {
      final value = await call('read', _view);
      if (_disposed || revision != _revision) return;
      final fingerprint = jsonEncode(value);
      _latest = value;
      if (_fingerprint != fingerprint) {
        _fingerprint = fingerprint;
        _updates.add(value);
      }
    } catch (error, stack) {
      if (!_disposed && revision == _revision) {
        _latest = null;
        _fingerprint = null;
        _updates.addError(error, stack);
      }
    } finally {
      _reading = false;
      if (_refreshAgain && !_disposed) {
        _refreshAgain = false;
        unawaited(refresh());
      }
    }
  }

  void dispose() {
    _disposed = true;
    _stop();
    unawaited(_updates.close());
  }
}

String newEventOperationId() {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random.secure();
  return List.generate(24, (_) => alphabet[random.nextInt(alphabet.length)]).join();
}
