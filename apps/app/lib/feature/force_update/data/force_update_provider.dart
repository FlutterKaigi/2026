import 'package:app/core/provider/package_info.dart';
import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:app/feature/force_update/data/force_update_config.dart';
import 'package:app/feature/force_update/data/force_update_state.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Platform facts the forced-update check depends on.
typedef ForceUpdateTarget = ({bool isWeb, TargetPlatform platform});

/// Exposes the running platform so tests can exercise the web, iOS and Android
/// branches without a real device.
final forceUpdateTargetProvider = Provider<ForceUpdateTarget>(
  (ref) => (isWeb: kIsWeb, platform: defaultTargetPlatform),
);

/// Whether the running build must be updated before it can be used.
final forceUpdateProvider = NotifierProvider<ForceUpdateNotifier, ForceUpdateState>(
  ForceUpdateNotifier.new,
);

/// Evaluates [RemoteConfigKeys.forceUpdate] against the running build.
class ForceUpdateNotifier extends Notifier<ForceUpdateState> {
  @override
  ForceUpdateState build() {
    // コンソールで最小バージョンを変えたら起動中のアプリにも反映されるよう、
    // Remote Config の更新とバージョン情報の解決を監視して再評価する。
    ref
      ..watch(remoteConfigUpdatesProvider)
      ..watch(packageInfoProvider);
    return _evaluate();
  }

  /// Fetches the latest policy and re-evaluates it.
  ///
  /// Called at startup and on every foreground return, on every platform: the
  /// web build has no realtime Remote Config channel, so this refresh is the
  /// only way its flags follow the console without a reload. The evaluation
  /// itself still never forces an update on the web, which has no store to
  /// send attendees to.
  Future<void> check() async {
    // refresh() は内部でログを出すだけで送出しないため、ここでの try は不要。
    await ref.read(remoteConfigRepositoryProvider).refresh();
    state = _evaluate();
  }

  ForceUpdateState _evaluate() {
    final target = ref.read(forceUpdateTargetProvider);
    final policy = ref.read(remoteConfigRepositoryProvider).getString(RemoteConfigKeys.forceUpdate);
    return evaluateForceUpdate(
      config: ForceUpdateConfig.parse(policy),
      // バージョンが読めるまでは更新不要として扱い、解決後に再評価される。
      currentVersion: ref.read(packageInfoProvider).value?.version ?? '',
      isWeb: target.isWeb,
      platform: target.platform,
    );
  }
}
