import 'dart:async';
import 'dart:convert';

import 'package:app/core/provider/environment.dart';
import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/core/remote_config/remote_config_repository.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'fake_remote_config_repository.dart';

/// Hand-written stand-in for [FirebaseRemoteConfig].
///
/// [FirebaseRemoteConfigRepository] takes its instance through the
/// constructor, so nothing here touches a platform channel. Only the members
/// the repository actually calls are implemented; `noSuchMethod` absorbs the
/// rest of the (large) interface, which keeps this free of extra test
/// dependencies.
class _FakeFirebaseRemoteConfig implements FirebaseRemoteConfig {
  /// Values visible to the getters. [setDefaults] seeds them and a successful
  /// [fetchAndActivate] merges [fetchedValues] on top, like an activation.
  final Map<String, Object?> values = {};

  /// What the next successful fetch activates.
  Map<String, Object> fetchedValues = const {};

  /// Completed by the test to decide when the fetch lands.
  ///
  /// Named `fetchResult` because `fetch` is itself a [FirebaseRemoteConfig]
  /// member.
  final Completer<bool> fetchResult = Completer<bool>();

  /// Set before `initialize()` to make the fetch fail immediately.
  ///
  /// A field rather than `fetchResult.completeError`, which would be reported
  /// as an unhandled async error before the repository attaches its handler.
  Exception? fetchError;

  final StreamController<RemoteConfigUpdate> _configUpdates = StreamController<RemoteConfigUpdate>.broadcast();

  int setDefaultsCount = 0;
  int fetchCount = 0;

  @override
  Future<void> setDefaults(Map<String, dynamic> defaultParameters) async {
    setDefaultsCount++;
    values.addAll(defaultParameters);
  }

  @override
  Future<void> setConfigSettings(RemoteConfigSettings remoteConfigSettings) async {}

  @override
  Future<bool> fetchAndActivate() async {
    fetchCount++;
    final error = fetchError;
    if (error != null) {
      throw error;
    }
    final activated = await fetchResult.future;
    if (activated) {
      values.addAll(fetchedValues);
    }
    return activated;
  }

  @override
  bool getBool(String key) => values[key] as bool? ?? false;

  @override
  String getString(String key) => values[key] as String? ?? '';

  @override
  Stream<RemoteConfigUpdate> get onConfigUpdated => _configUpdates.stream;

  Future<void> close() => _configUpdates.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('remoteConfigDefaults', () {
    test('covers every declared key', () {
      expect(
        remoteConfigDefaults.keys,
        containsAll(<String>[RemoteConfigKeys.eventFeaturesEnabled, RemoteConfigKeys.forceUpdate]),
      );
    });

    test('shows the event features until a fetch says otherwise', () {
      expect(remoteConfigDefaults[RemoteConfigKeys.eventFeaturesEnabled], isTrue);
    });

    test('ships a force update policy that never forces an update', () {
      final policy = jsonDecode(defaultForceUpdateJson) as Map<String, dynamic>;

      expect(policy['minimum_version'], {'ios': '0.0.0', 'android': '0.0.0'});
      expect(policy['message'], {'ja': '', 'en': ''});
      final storeUrls = policy['store_urls']! as Map<String, dynamic>;
      expect(storeUrls['ios'], '');
      expect(storeUrls['android'], contains('jp.flutterkaigi.conf2026'));
    });
  });

  group('FakeRemoteConfigRepository', () {
    test('falls back to the production defaults for unset keys', () {
      final repository = FakeRemoteConfigRepository();
      addTearDown(repository.dispose);

      expect(repository.getBool(RemoteConfigKeys.eventFeaturesEnabled), isTrue);
      expect(repository.getString(RemoteConfigKeys.forceUpdate), defaultForceUpdateJson);
    });

    test('returns the values supplied at construction', () {
      final repository = FakeRemoteConfigRepository(
        initialValues: const {RemoteConfigKeys.eventFeaturesEnabled: false},
      );
      addTearDown(repository.dispose);

      expect(repository.getBool(RemoteConfigKeys.eventFeaturesEnabled), isFalse);
    });

    test('setValue replaces the value and notifies onUpdated', () async {
      final repository = FakeRemoteConfigRepository();
      addTearDown(repository.dispose);
      var updates = 0;
      final subscription = repository.onUpdated.listen((_) {
        updates++;
      });
      addTearDown(subscription.cancel);

      repository.setValue(RemoteConfigKeys.eventFeaturesEnabled, false);
      await pumpEventQueue();

      expect(updates, 1);
      expect(repository.getBool(RemoteConfigKeys.eventFeaturesEnabled), isFalse);
    });
  });

  group('FirebaseRemoteConfigRepository.initialize', () {
    /// Builds the repository under test together with its fake.
    ///
    /// Everything is created inside the test body on purpose: a [Completer]
    /// made in `setUp` would capture the surrounding zone, while
    /// `tester.pump()` only drains the microtasks of the fake-time zone a
    /// [testWidgets] body runs in — its completion would never be delivered.
    (_FakeFirebaseRemoteConfig, FirebaseRemoteConfigRepository) createRepository({
      Flavor flavor = Flavor.production,
    }) {
      final remoteConfig = _FakeFirebaseRemoteConfig();
      addTearDown(remoteConfig.close);
      final repository = FirebaseRemoteConfigRepository(
        flavor: flavor,
        talker: Talker(),
        remoteConfig: remoteConfig,
      );
      addTearDown(repository.dispose);
      return (remoteConfig, repository);
    }

    test('serves the fetched values when the first fetch lands in time', () async {
      final (remoteConfig, repository) = createRepository();
      remoteConfig
        ..fetchedValues = {RemoteConfigKeys.eventFeaturesEnabled: false}
        ..fetchResult.complete(true);

      await repository.initialize();

      expect(remoteConfig.setDefaultsCount, 1);
      expect(remoteConfig.fetchCount, 1);
      expect(repository.getBool(RemoteConfigKeys.eventFeaturesEnabled), isFalse);
    });

    // 実時間では待たず、testWidgets の仮想時間で3秒を進める。
    // (fake_async の直接 import は depend_on_referenced_packages に掛かるため)
    testWidgets('returns after the startup wait and applies a fetch that lands late', (tester) async {
      final (remoteConfig, repository) = createRepository();
      remoteConfig.fetchedValues = {RemoteConfigKeys.eventFeaturesEnabled: false};

      var updates = 0;
      final subscription = repository.onUpdated.listen((_) => updates++);
      addTearDown(subscription.cancel);

      var initialized = false;
      unawaited(repository.initialize().then((_) => initialized = true));

      await tester.pump(const Duration(seconds: 2));
      expect(initialized, isFalse, reason: 'the startup wait is 3s, not 2s');

      await tester.pump(const Duration(seconds: 1));
      expect(initialized, isTrue, reason: 'a slow fetch must not block startup any longer');
      // 待ちを打ち切った時点ではデフォルト値のまま。
      expect(repository.getBool(RemoteConfigKeys.eventFeaturesEnabled), isTrue);
      expect(updates, 0);

      // 打ち切ったあとも fetch は生きており、着地すれば購読者に届く。
      remoteConfig.fetchResult.complete(true);
      await tester.pump();

      expect(updates, 1);
      expect(repository.getBool(RemoteConfigKeys.eventFeaturesEnabled), isFalse);
    });

    testWidgets('does not emit when a fetch that landed late changed nothing', (tester) async {
      final (remoteConfig, repository) = createRepository();

      var updates = 0;
      final subscription = repository.onUpdated.listen((_) => updates++);
      addTearDown(subscription.cancel);

      unawaited(repository.initialize());
      await tester.pump(const Duration(seconds: 3));

      remoteConfig.fetchResult.complete(false);
      await tester.pump();

      expect(updates, 0);
    });

    test('does not throw when the first fetch fails', () async {
      final (remoteConfig, repository) = createRepository();
      remoteConfig.fetchError = Exception('network is unreachable');

      await expectLater(repository.initialize(), completes);

      expect(remoteConfig.fetchCount, 1);
      expect(repository.getBool(RemoteConfigKeys.eventFeaturesEnabled), isTrue);
    });

    testWidgets('logs but does not rethrow a fetch that fails after the startup wait', (tester) async {
      final (remoteConfig, repository) = createRepository();

      var initialized = false;
      unawaited(repository.initialize().then((_) => initialized = true));
      await tester.pump(const Duration(seconds: 3));
      expect(initialized, isTrue);

      // 未処理の非同期エラーになっていれば、ここで Zone のエラーとしてテストが落ちる。
      remoteConfig.fetchResult.completeError(Exception('network is unreachable'));
      await tester.pump();

      expect(repository.getBool(RemoteConfigKeys.eventFeaturesEnabled), isTrue);
    });

    test('runs on the defaults alone in the develop flavor', () async {
      final (remoteConfig, repository) = createRepository(flavor: Flavor.develop);

      await repository.initialize();

      expect(remoteConfig.setDefaultsCount, 1);
      expect(remoteConfig.fetchCount, 0);
      expect(repository.getBool(RemoteConfigKeys.eventFeaturesEnabled), isTrue);
    });
  });
}
