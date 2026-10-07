import 'dart:async';

import 'package:app/core/provider/environment.dart';
import 'package:app/feature/push_notification/data/notification_route.dart';
import 'package:app/feature/push_notification/data/push_notification_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

class _FakeFirebaseMessaging implements FirebaseMessaging {
  /// Runs on the first call of any member, like the plugin releasing the platform messages that waited for its Dart
  /// handler.
  void Function()? onFirstCall;

  Future<RemoteMessage?> Function() initialMessage = () async => null;
  AuthorizationStatus status = AuthorizationStatus.notDetermined;
  Exception? permissionError;
  Exception? tokenError;
  String? apnsToken;
  ({bool alert, bool badge, bool sound})? presentationOptions;
  final permissionRequests = <({bool alert, bool badge, bool sound})>[];
  int getTokenCount = 0;
  final tokenRefresh = StreamController<String>.broadcast();

  var _called = false;

  void _call() {
    if (!_called) {
      _called = true;
      onFirstCall?.call();
    }
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
  }) async {
    _call();
    presentationOptions = (alert: alert, badge: badge, sound: sound);
  }

  @override
  Stream<String> get onTokenRefresh {
    _call();
    return tokenRefresh.stream;
  }

  @override
  Future<RemoteMessage?> getInitialMessage() {
    _call();
    return initialMessage();
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    _call();
    if (permissionError case final error?) {
      throw error;
    }
    return _settings(status);
  }

  /// Answers without changing [status], so asking again would show the prompt again.
  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    _call();
    permissionRequests.add((alert: alert, badge: badge, sound: sound));
    return _settings(AuthorizationStatus.authorized);
  }

  @override
  Future<String?> getAPNSToken() async {
    _call();
    return apnsToken;
  }

  @override
  Future<String?> getToken({String? vapidKey, String? serviceWorkerScriptPath}) async {
    _call();
    getTokenCount++;
    if (tokenError case final error?) {
      throw error;
    }
    return 'fcm-token';
  }

  Future<void> close() => tokenRefresh.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  static NotificationSettings _settings(AuthorizationStatus status) => NotificationSettings(
    alert: AppleNotificationSetting.notSupported,
    announcement: AppleNotificationSetting.notSupported,
    authorizationStatus: status,
    badge: AppleNotificationSetting.notSupported,
    carPlay: AppleNotificationSetting.notSupported,
    lockScreen: AppleNotificationSetting.notSupported,
    notificationCenter: AppleNotificationSetting.notSupported,
    showPreviews: AppleShowPreviewSetting.notSupported,
    timeSensitive: AppleNotificationSetting.notSupported,
    criticalAlert: AppleNotificationSetting.notSupported,
    sound: AppleNotificationSetting.notSupported,
    providesAppNotificationSettings: AppleNotificationSetting.notSupported,
  );
}

/// The repository under test with broadcast controllers standing in for the plugin's static streams, so an event
/// nobody listens to is lost as in production.
///
/// Create it inside each test body, as remote_config_test.dart does, so that `testWidgets` runs it in its fake-async
/// zone.
final class _Subject {
  _Subject({this.platform = TargetPlatform.android}) {
    addTearDown(() async {
      await repository.dispose();
      await onMessage.close();
      await onMessageOpenedApp.close();
      await messaging.close();
    });
  }

  final TargetPlatform platform;
  final messaging = _FakeFirebaseMessaging();
  final onMessage = StreamController<RemoteMessage>.broadcast();
  final onMessageOpenedApp = StreamController<RemoteMessage>.broadcast();
  final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
  late final repository = FirebasePushNotificationRepository(
    talker: talker,
    messaging: messaging,
    onMessage: onMessage.stream,
    onMessageOpenedApp: onMessageOpenedApp.stream,
    platform: platform,
  );

  List<NotificationRoute> collectOpened() {
    final opened = <NotificationRoute>[];
    final subscription = repository.onOpened.listen(opened.add);
    addTearDown(subscription.cancel);
    return opened;
  }

  List<ForegroundNotification> collectForeground() {
    final shown = <ForegroundNotification>[];
    final subscription = repository.onForeground.listen(shown.add);
    addTearDown(subscription.cancel);
    return shown;
  }

  List<String?> logsAt(LogLevel level) => [
    for (final log in talker.history)
      if (log.logLevel == level) log.message,
  ];
}

RemoteMessage _tap(String? id, {String? route}) => RemoteMessage(
  messageId: id,
  data: {notificationRouteKey: ?route},
  notification: const RemoteNotification(title: 'お知らせ', body: '本文'),
);

NotificationRoute _route(String path) => parseNotificationRoute(path)!;

void main() {
  test('receives notifications in the stg and prod native apps only', () {
    expect(isPushNotificationSupported(flavor: Flavor.production, isWeb: false), isTrue);
    expect(isPushNotificationSupported(flavor: Flavor.staging, isWeb: false), isTrue);
    expect(isPushNotificationSupported(flavor: Flavor.develop, isWeb: false), isFalse);
    for (final flavor in Flavor.values) {
      expect(isPushNotificationSupported(flavor: flavor, isWeb: true), isFalse, reason: flavor.name);
    }
  });

  test('gives the develop flavor a repository that never touches the plugin', () async {
    final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    final repository = createPushNotificationRepository(flavor: Flavor.develop, talker: talker);
    final events = <Object>[];
    final foreground = repository.onForeground.listen(events.add);
    addTearDown(foreground.cancel);
    final opened = repository.onOpened.listen(events.add);
    addTearDown(opened.cancel);

    expect(await repository.initialize(), isNull);
    await expectLater(repository.requestPermission(), completes);
    await pumpEventQueue();

    expect(events, isEmpty);
    expect(talker.history, isEmpty, reason: 'without a Firebase app, any FirebaseMessaging call logs an error');
  });

  group('initialize', () {
    test('listens to the plugin before its first call, which releases the taps reported so far', () async {
      final subject = _Subject();
      subject.messaging.onFirstCall = () => subject.onMessageOpenedApp.add(_tap('m1', route: '/news'));

      expect(await subject.repository.initialize(), _route('/news'));
    });

    test('returns the route of the notification that launched the app and does not open it again', () async {
      final subject = _Subject();
      subject.messaging.initialMessage = () async => _tap('m1', route: '/news');

      expect(await subject.repository.initialize(), _route('/news'));

      final opened = subject.collectOpened();
      subject.onMessageOpenedApp.add(_tap('m1', route: '/news'));
      await pumpEventQueue();
      expect(opened, isEmpty);
    });

    test('returns a launch tap reported both as the launch message and as opened once', () async {
      final subject = _Subject();
      subject.messaging.onFirstCall = () => subject.onMessageOpenedApp.add(_tap('m1', route: '/news'));
      subject.messaging.initialMessage = () async => _tap('m1', route: '/news');

      expect(await subject.repository.initialize(), _route('/news'));

      final opened = subject.collectOpened();
      await pumpEventQueue();
      expect(opened, isEmpty);
    });

    test('returns no route and logs a warning for an invalid launch route', () async {
      final subject = _Subject();
      subject.messaging.initialMessage = () async => _tap('m1', route: 'https://example.com/news');

      expect(await subject.repository.initialize(), isNull);
      expect(subject.logsAt(LogLevel.warning), [contains('https://example.com/news')]);
    });

    test('returns no route when the launching notification cannot be read', () async {
      for (final (description, answer) in <(String, Future<RemoteMessage?> Function())>[
        ('synchronously', () => throw Exception('channel-error')),
        ('asynchronously', () async => throw Exception('channel-error')),
      ]) {
        final subject = _Subject();
        subject.messaging.initialMessage = answer;

        expect(await subject.repository.initialize(), isNull, reason: description);
        expect(subject.logsAt(LogLevel.error), ['Failed to read the notification that launched the app']);
      }
    });

    // 実時間では待たず、testWidgets の仮想時間で1秒を進める。
    testWidgets('waits a second at most and opens a launch tap answered later', (tester) async {
      final subject = _Subject();
      final answer = Completer<RemoteMessage?>();
      subject.messaging.initialMessage = () => answer.future;

      var initialized = false;
      NotificationRoute? launchRoute;
      unawaited(
        subject.repository.initialize().then((route) {
          initialized = true;
          launchRoute = route;
        }),
      );

      await tester.pump(const Duration(milliseconds: 999));
      expect(initialized, isFalse, reason: 'the wait is one second');
      await tester.pump(const Duration(milliseconds: 1));
      expect(initialized, isTrue, reason: 'a plugin that does not answer must not hold up startup');
      expect(launchRoute, isNull);

      final opened = subject.collectOpened();
      answer.complete(_tap('m1', route: '/news'));
      await tester.pump();
      expect(opened, [_route('/news')]);
    });
  });

  group('onOpened', () {
    test('opens each tap once, deduplicating by message ID only', () async {
      final subject = _Subject();
      await subject.repository.initialize();
      final opened = subject.collectOpened();

      subject.onMessageOpenedApp
        ..add(_tap('a', route: '/news'))
        ..add(_tap('b', route: '/sessions/abc'))
        ..add(_tap('a', route: '/news'))
        ..add(_tap(null, route: '/venue-map'))
        ..add(_tap(null, route: '/venue-map'));
      await pumpEventQueue();

      expect(opened, [_route('/news'), _route('/sessions/abc'), _route('/venue-map'), _route('/venue-map')]);
    });

    test('keeps taps that arrive before anyone listens for the first listener, in order', () async {
      final subject = _Subject();
      await subject.repository.initialize();
      subject.onMessageOpenedApp
        ..add(_tap('a', route: '/news'))
        ..add(_tap('b', route: '/venue-map'));
      await pumpEventQueue();

      final opened = subject.collectOpened();
      await pumpEventQueue();

      expect(opened, [_route('/news'), _route('/venue-map')]);
    });

    test('opens nothing for a tap without a valid route', () async {
      final subject = _Subject();
      await subject.repository.initialize();
      final opened = subject.collectOpened();

      subject.onMessageOpenedApp
        ..add(_tap('a'))
        ..add(_tap('b', route: '/x/v1.other-uid.9999999999.deadbeef'));
      await pumpEventQueue();

      expect(opened, isEmpty);
      expect(subject.logsAt(LogLevel.warning), [contains('/x/v1.other-uid.9999999999.deadbeef')]);
    });
  });

  group('onForeground', () {
    test('emits Android notification messages with their route and skips data-only messages', () async {
      final subject = _Subject();
      await subject.repository.initialize();
      final shown = subject.collectForeground();

      subject.onMessage
        ..add(const RemoteMessage(messageId: 'm1', data: {'kind': 'silent'}))
        ..add(
          const RemoteMessage(
            messageId: 'm2',
            notification: RemoteNotification(title: '開場', body: '受付を開始しました'),
            data: {notificationRouteKey: '/news'},
          ),
        );
      await pumpEventQueue();

      expect(shown, hasLength(1));
      expect((shown.single.title, shown.single.body, shown.single.route), ('開場', '受付を開始しました', _route('/news')));
    });

    test('leaves iOS notification messages to the system banner, without a badge', () async {
      final subject = _Subject(platform: TargetPlatform.iOS);
      await subject.repository.initialize();
      final shown = subject.collectForeground();

      subject.onMessage.add(_tap('m1', route: '/news'));
      await pumpEventQueue();

      expect(shown, isEmpty);
      expect(subject.messaging.presentationOptions, (alert: true, badge: false, sound: true));
    });
  });

  group('requestPermission', () {
    test('asks once per process, without the badge, while the user has not decided', () async {
      final subject = _Subject();

      await subject.repository.requestPermission();
      await subject.repository.requestPermission();

      expect(subject.messaging.permissionRequests, [(alert: true, badge: false, sound: true)]);
    });

    test('never asks after the user decided', () async {
      for (final status in [
        AuthorizationStatus.authorized,
        AuthorizationStatus.denied,
        AuthorizationStatus.deniedPermanently,
        AuthorizationStatus.provisional,
      ]) {
        final subject = _Subject();
        subject.messaging.status = status;

        await subject.repository.requestPermission();

        expect(subject.messaging.permissionRequests, isEmpty, reason: status.name);
      }
    });

    test('logs the FCM registration token afterwards', () async {
      final subject = _Subject();

      await subject.repository.requestPermission();

      expect(subject.logsAt(LogLevel.info), contains('FCM registration token: fcm-token'));
    });

    test('logs the FCM registration token on iOS once it is issued after APNs registration', () async {
      final subject = _Subject(platform: TargetPlatform.iOS);
      await subject.repository.initialize();

      await subject.repository.requestPermission();
      expect(subject.messaging.getTokenCount, 0, reason: 'getToken throws apns-token-not-set without an APNs token');

      subject.messaging.tokenRefresh.add('issued-token');
      await pumpEventQueue();
      expect(subject.logsAt(LogLevel.info), contains('FCM registration token: issued-token'));
    });

    test('completes when the plugin fails', () async {
      final subject = _Subject();
      subject.messaging
        ..permissionError = Exception('settings')
        ..tokenError = Exception('token');

      await expectLater(subject.repository.requestPermission(), completes);

      expect(subject.logsAt(LogLevel.error), [
        'Failed to request the notification permission',
        'Failed to read the FCM registration token',
      ]);
    });
  });

  test('dispose stops listening to the plugin', () async {
    final subject = _Subject();
    await subject.repository.initialize();
    bool listening() =>
        subject.onMessage.hasListener ||
        subject.onMessageOpenedApp.hasListener ||
        subject.messaging.tokenRefresh.hasListener;
    expect(listening(), isTrue);

    await subject.repository.dispose();

    expect(listening(), isFalse);
  });
}
