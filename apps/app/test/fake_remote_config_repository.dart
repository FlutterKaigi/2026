import 'dart:async';

import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/core/remote_config/remote_config_repository.dart';

final class FakeRemoteConfigRepository implements RemoteConfigRepository {
  FakeRemoteConfigRepository({Map<String, Object> initialValues = const {}}) : values = {...initialValues};

  /// Explicitly set values. Unset keys fall back to [remoteConfigDefaults].
  final Map<String, Object> values;
  final _controller = StreamController<void>.broadcast();
  int initializeCount = 0;
  int refreshCount = 0;

  @override
  Stream<void> get onUpdated => _controller.stream;

  @override
  Future<void> initialize() async {
    initializeCount++;
  }

  @override
  Future<void> refresh() async {
    refreshCount++;
  }

  @override
  bool getBool(String key) => switch (values[key] ?? remoteConfigDefaults[key]) {
    final bool value => value,
    _ => false,
  };

  @override
  String getString(String key) => switch (values[key] ?? remoteConfigDefaults[key]) {
    final String value => value,
    _ => '',
  };

  /// Replaces [key] with [value] and notifies [onUpdated].
  void setValue(String key, Object value) {
    values[key] = value;
    _controller.add(null);
  }

  void dispose() => unawaited(_controller.close());
}
