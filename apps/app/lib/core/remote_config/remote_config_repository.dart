import 'dart:async';

import 'package:app/core/provider/environment.dart';
import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Reads the feature flags and rollout settings delivered by Remote Config.
///
/// Every member fails open: failures are logged and the last activated values
/// (or [remoteConfigDefaults]) keep being served, so a Remote Config outage
/// never blocks the app.
abstract interface class RemoteConfigRepository {
  /// Applies [remoteConfigDefaults], configures fetching and starts the first
  /// fetch.
  ///
  /// Returns as soon as that fetch lands, or after a short startup wait —
  /// whichever comes first. A fetch that outlives the wait keeps running and
  /// reports on [onUpdated]. Does not throw.
  Future<void> initialize();

  /// Fetches and activates again, honouring `minimumFetchInterval`.
  ///
  /// Emits on [onUpdated] when the activated values actually changed.
  /// Does not throw.
  Future<void> refresh();

  /// The bool value of [key], falling back to its default.
  bool getBool(String key);

  /// The String value of [key], falling back to its default.
  String getString(String key);

  /// Emits every time newly activated values became visible to [getBool] and
  /// [getString]. Broadcast, so any number of listeners may subscribe late.
  Stream<void> get onUpdated;
}

/// Upper bound for a single fetch.
const _fetchTimeout = Duration(seconds: 10);

/// How long [FirebaseRemoteConfigRepository.initialize] blocks startup on the
/// first fetch before continuing with the cached or default values.
///
/// Kept well below [_fetchTimeout]: on a congested venue network the first
/// frame matters more than the freshest flags, and a late fetch still reaches
/// the UI through [RemoteConfigRepository.onUpdated].
const _initialFetchWait = Duration(seconds: 3);

/// How long fetched values stay fresh outside debug builds.
const _minimumFetchInterval = Duration(minutes: 10);

const _fetchFailureMessage = 'Remote Config fetch failed; continuing with cached or default values';

final class FirebaseRemoteConfigRepository implements RemoteConfigRepository {
  FirebaseRemoteConfigRepository({
    required this.flavor,
    required this.talker,
    FirebaseRemoteConfig? remoteConfig,
  }) : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final Flavor flavor;
  final Talker talker;
  final FirebaseRemoteConfig _remoteConfig;
  final _updates = StreamController<void>.broadcast();
  StreamSubscription<RemoteConfigUpdate>? _configUpdates;

  /// The develop flavor points at the Emulator Suite, which does not serve
  /// Remote Config, so it runs on the defaults alone.
  bool get _usesDefaultsOnly => flavor == Flavor.develop;

  @override
  Stream<void> get onUpdated => _updates.stream;

  @override
  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults(remoteConfigDefaults);
    } on Exception catch (error, stackTrace) {
      talker.handle(error, stackTrace, 'Failed to apply the Remote Config defaults');
      return;
    }

    if (_usesDefaultsOnly) {
      return;
    }

    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: _fetchTimeout,
          minimumFetchInterval: kDebugMode ? Duration.zero : _minimumFetchInterval,
        ),
      );
    } on Exception catch (error, stackTrace) {
      talker.handle(error, stackTrace, 'Failed to apply the Remote Config settings');
    }

    // リアルタイム購読は初回 fetch の待ち時間とは独立に張る。
    _listenForConfigUpdates();

    await _runInitialFetch();
  }

  /// Starts the first fetch and waits at most [_initialFetchWait] for it.
  ///
  /// The fetch itself is never cancelled: once the startup wait is over it
  /// keeps running under its own [_fetchTimeout], and a late success is
  /// published on [onUpdated] so the values still reach the UI.
  Future<void> _runInitialFetch() async {
    final startupWait = Completer<void>();
    var startupWaitIsOver = false;

    void finishStartupWait() {
      startupWaitIsOver = true;
      if (!startupWait.isCompleted) {
        startupWait.complete();
      }
    }

    final Future<bool> fetch;
    try {
      fetch = _remoteConfig.fetchAndActivate();
    } on Exception catch (error, stackTrace) {
      talker.handle(error, stackTrace, _fetchFailureMessage);
      return;
    }

    // 起動待ちを打ち切ったあとも fetch の Future は生き続けるため、ここで
    // 成功・失敗の両方に必ずハンドラを付けて未処理の非同期エラーを防ぐ。
    // `unawaited` しているのはこのチェーン自体で、チェーンはエラーを
    // 送出しない(catchError で握り潰す)。
    unawaited(
      fetch
          .then((activated) {
            if (!startupWaitIsOver) {
              finishStartupWait();
              return;
            }
            // 待ちを打ち切ったあとに届いた値。購読者はすでにいるので、
            // ここで通知して画面に反映させる。
            if (activated && !_updates.isClosed) {
              _updates.add(null);
            }
          })
          .catchError((Object error, StackTrace stackTrace) {
            talker.handle(error, stackTrace, _fetchFailureMessage);
            finishStartupWait();
          }),
    );

    await startupWait.future.timeout(
      _initialFetchWait,
      onTimeout: () {
        finishStartupWait();
        talker.warning('Remote Config fetch is still running after $_initialFetchWait; starting with cached values');
      },
    );
  }

  @override
  Future<void> refresh() async {
    if (_usesDefaultsOnly) {
      return;
    }
    try {
      final activated = await _remoteConfig.fetchAndActivate().timeout(_fetchTimeout);
      if (activated) {
        _updates.add(null);
      }
    } on Exception catch (error, stackTrace) {
      talker.handle(error, stackTrace, 'Remote Config refresh failed');
    }
  }

  @override
  bool getBool(String key) => _remoteConfig.getBool(key);

  @override
  String getString(String key) => _remoteConfig.getString(key);

  /// Releases the realtime subscription and the update stream.
  Future<void> dispose() async {
    await _configUpdates?.cancel();
    await _updates.close();
  }

  /// Subscribes to realtime updates so that a change published during the
  /// conference lands without a restart.
  ///
  /// The Web SDK has no realtime channel, so the web build relies on
  /// [refresh] instead.
  void _listenForConfigUpdates() {
    if (kIsWeb) {
      return;
    }
    try {
      _configUpdates = _remoteConfig.onConfigUpdated.listen(
        (_) => unawaited(_activateUpdate()),
        onError: (Object error, StackTrace stackTrace) =>
            talker.handle(error, stackTrace, 'Remote Config realtime updates stopped'),
      );
    } on Exception catch (error, stackTrace) {
      talker.handle(error, stackTrace, 'Failed to subscribe to Remote Config realtime updates');
    }
  }

  Future<void> _activateUpdate() async {
    try {
      await _remoteConfig.activate();
      _updates.add(null);
    } on Exception catch (error, stackTrace) {
      talker.handle(error, stackTrace, 'Failed to activate a realtime Remote Config update');
    }
  }
}
