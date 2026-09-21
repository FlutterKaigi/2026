import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/feature/force_update/data/force_update_config.dart';
import 'package:app/feature/force_update/data/force_update_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _policy =
    '{"minimum_version":{"ios":"1.2.0","android":"1.3.0"},'
    '"store_urls":{"ios":"https://apps.apple.com/app/id1","android":"https://play.google.com/store"},'
    '"message":{"ja":"更新してください","en":"Please update"}}';

void main() {
  group('ForceUpdateConfig.parse', () {
    test('reads every section of a well formed policy', () {
      final config = ForceUpdateConfig.parse(_policy);

      expect(config.minimumVersionFor(TargetPlatform.iOS), '1.2.0');
      expect(config.minimumVersionFor(TargetPlatform.android), '1.3.0');
      expect(config.storeUrlFor(TargetPlatform.iOS), 'https://apps.apple.com/app/id1');
      expect(config.storeUrlFor(TargetPlatform.android), 'https://play.google.com/store');
      expect(config.messages, {'ja': '更新してください', 'en': 'Please update'});
    });

    test('reads the policy shipped as the Remote Config default', () {
      final config = ForceUpdateConfig.parse(defaultForceUpdateJson);

      expect(config.minimumVersionFor(TargetPlatform.iOS), '0.0.0');
      expect(config.storeUrlFor(TargetPlatform.iOS), '');
      expect(config.storeUrlFor(TargetPlatform.android), contains('jp.flutterkaigi.conf2026'));
    });

    test('falls back to an empty policy for malformed JSON', () {
      for (final source in const ['', 'not json', '[]', '{"minimum_version":']) {
        final config = ForceUpdateConfig.parse(source);

        expect(config.minimumVersionFor(TargetPlatform.android), '', reason: source);
        expect(config.messages, isEmpty, reason: source);
      }
    });

    test('keeps the usable parts when keys are missing or mistyped', () {
      final config = ForceUpdateConfig.parse(
        '{"minimum_version":{"android":"2.0.0","ios":7},"message":"broken"}',
      );

      expect(config.minimumVersionFor(TargetPlatform.android), '2.0.0');
      expect(config.minimumVersionFor(TargetPlatform.iOS), '');
      expect(config.storeUrlFor(TargetPlatform.android), '');
      expect(config.messages, isEmpty);
    });

    test('has no policy for platforms without a store', () {
      final config = ForceUpdateConfig.parse(_policy);

      expect(forceUpdatePlatformKey(TargetPlatform.macOS), isNull);
      expect(config.minimumVersionFor(TargetPlatform.macOS), '');
      expect(config.storeUrlFor(TargetPlatform.macOS), '');
    });
  });

  group('isUpdateRequired', () {
    test('requires an update only below the minimum version', () {
      expect(isUpdateRequired(currentVersion: '1.1.9', minimumVersion: '1.2.0'), isTrue);
      expect(isUpdateRequired(currentVersion: '1.2.0', minimumVersion: '1.2.0'), isFalse);
      expect(isUpdateRequired(currentVersion: '1.2.1', minimumVersion: '1.2.0'), isFalse);
    });

    test('fails open on version strings it cannot parse', () {
      expect(isUpdateRequired(currentVersion: '', minimumVersion: '1.2.0'), isFalse);
      expect(isUpdateRequired(currentVersion: 'v1', minimumVersion: '1.2.0'), isFalse);
      expect(isUpdateRequired(currentVersion: '1.0.0', minimumVersion: 'unreleased'), isFalse);
    });
  });

  group('evaluateForceUpdate', () {
    ForceUpdateState evaluate({
      required String currentVersion,
      required TargetPlatform platform,
      bool isWeb = false,
      String policy = _policy,
    }) => evaluateForceUpdate(
      config: ForceUpdateConfig.parse(policy),
      currentVersion: currentVersion,
      isWeb: isWeb,
      platform: platform,
    );

    test('picks the minimum version and store URL of the running platform', () {
      final ios = evaluate(currentVersion: '1.2.0', platform: TargetPlatform.iOS);
      final android = evaluate(currentVersion: '1.2.0', platform: TargetPlatform.android);

      // iOS は 1.2.0 以上、Android は 1.3.0 以上を要求するポリシー。
      expect(ios.isUpdateRequired, isFalse);
      expect(android.isUpdateRequired, isTrue);
      expect(android.storeUrl, 'https://play.google.com/store');
      expect(android.messages, {'ja': '更新してください', 'en': 'Please update'});
    });

    test('never forces an update on the web', () {
      final state = evaluate(currentVersion: '1.0.0', platform: TargetPlatform.android, isWeb: true);

      expect(state, ForceUpdateState.notRequired);
    });

    test('never forces an update on platforms without a store', () {
      final state = evaluate(currentVersion: '1.0.0', platform: TargetPlatform.macOS);

      expect(state, ForceUpdateState.notRequired);
    });

    test('never forces an update from a broken policy', () {
      final state = evaluate(currentVersion: '1.0.0', platform: TargetPlatform.android, policy: 'not json');

      expect(state, ForceUpdateState.notRequired);
    });
  });

  group('ForceUpdateState.messageFor', () {
    test('returns the remote message only when one was published', () {
      const state = ForceUpdateState(
        isUpdateRequired: true,
        messages: {'ja': '更新してください', 'en': ''},
      );

      expect(state.messageFor('ja'), '更新してください');
      expect(state.messageFor('en'), isNull);
      expect(state.messageFor('fr'), isNull);
    });

    test('compares equal when the published messages are equal', () {
      const a = ForceUpdateState(isUpdateRequired: true, storeUrl: 'https://example.com', messages: {'ja': 'a'});
      const b = ForceUpdateState(isUpdateRequired: true, storeUrl: 'https://example.com', messages: {'ja': 'a'});

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
