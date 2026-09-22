import 'package:app/core/provider/package_info.dart';
import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:app/feature/force_update/data/force_update_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fake_remote_config_repository.dart';

/// iOS だけが 2.0.0 以上を要求するポリシー。
const _policy =
    '{"minimum_version":{"ios":"2.0.0","android":"1.0.0"},'
    '"store_urls":{"ios":"","android":"https://play.google.com/store"},'
    '"message":{"ja":"更新してください","en":""}}';

void main() {
  late FakeRemoteConfigRepository repository;

  setUp(() => repository = FakeRemoteConfigRepository());
  tearDown(() => repository.dispose());

  ProviderContainer createContainer({
    required TargetPlatform platform,
    bool isWeb = false,
    String version = '1.0.0',
  }) {
    final container = ProviderContainer(
      overrides: [
        remoteConfigRepositoryProvider.overrideWithValue(repository),
        forceUpdateTargetProvider.overrideWithValue((isWeb: isWeb, platform: platform)),
        packageInfoProvider.overrideWithValue(
          AsyncData(
            PackageInfo(
              appName: 'FlutterKaigi 2026',
              packageName: 'jp.flutterkaigi.conf2026',
              version: version,
              buildNumber: '1',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    // ストリーム更新を受け取れるよう購読を張っておく。
    container.listen(forceUpdateProvider, (_, _) {});
    return container;
  }

  test('refreshes on the web but never forces an update there', () async {
    repository.values[RemoteConfigKeys.forceUpdate] = _policy;
    final container = createContainer(isWeb: true, platform: TargetPlatform.iOS);

    await container.read(forceUpdateProvider.notifier).check();

    // Web はリアルタイム更新が使えないため、refresh だけは全プラットフォームで行う。
    expect(repository.refreshCount, 1);
    // 最小バージョンを満たしていなくても、Web には送り先のストアがないので更新不要のまま。
    expect(container.read(forceUpdateProvider).isUpdateRequired, isFalse);
  });

  test('applies the minimum version of the running platform', () async {
    repository.values[RemoteConfigKeys.forceUpdate] = _policy;

    final ios = createContainer(platform: TargetPlatform.iOS);
    await ios.read(forceUpdateProvider.notifier).check();
    final iosState = ios.read(forceUpdateProvider);

    final android = createContainer(platform: TargetPlatform.android);
    await android.read(forceUpdateProvider.notifier).check();
    final androidState = android.read(forceUpdateProvider);

    expect(iosState.isUpdateRequired, isTrue);
    // iOS のストア URL は未設定なので空のまま渡る。
    expect(iosState.storeUrl, '');
    expect(iosState.messageFor('ja'), '更新してください');
    expect(androidState.isUpdateRequired, isFalse);
  });

  test('refreshes Remote Config on every check', () async {
    final container = createContainer(platform: TargetPlatform.iOS);
    final notifier = container.read(forceUpdateProvider.notifier);

    await notifier.check();
    await notifier.check();

    expect(repository.refreshCount, 2);
  });

  test('never forces an update with the shipped defaults', () async {
    final container = createContainer(platform: TargetPlatform.iOS);

    await container.read(forceUpdateProvider.notifier).check();

    expect(container.read(forceUpdateProvider).isUpdateRequired, isFalse);
  });

  test('reacts to a policy published while the app is running', () async {
    final container = createContainer(platform: TargetPlatform.iOS);
    expect(container.read(forceUpdateProvider).isUpdateRequired, isFalse);

    repository.setValue(RemoteConfigKeys.forceUpdate, _policy);
    await pumpEventQueue();

    expect(container.read(forceUpdateProvider).isUpdateRequired, isTrue);

    // 最小バージョンを下げれば起動中のアプリからも消える。
    repository.setValue(
      RemoteConfigKeys.forceUpdate,
      '{"minimum_version":{"ios":"0.9.0","android":"0.9.0"}}',
    );
    await pumpEventQueue();

    expect(container.read(forceUpdateProvider).isUpdateRequired, isFalse);
  });
}
