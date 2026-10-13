import 'dart:async';

import 'package:app/core/provider/environment.dart';
import 'package:app/feature/push_notification/data/notification_route.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// A notification message that arrived while the app was in the foreground and that the OS does not display
/// itself (Android).
///
/// Invariant: [title] or [body] is non-null.
final class ForegroundNotification {
  const ForegroundNotification({this.title, this.body, this.route})
    : assert(title != null || body != null, 'A notification has a title or a body');

  final String? title;
  final String? body;

  /// Where the notification leads, or `null` when it carries no valid [notificationRouteKey].
  final NotificationRoute? route;
}

/// Receives the notification messages operators send from the Firebase console.
///
/// Every member fails open: failures are logged and swallowed, so push notifications never block startup or break
/// the UI.
abstract interface class PushNotificationRepository {
  /// Wires FCM for this process and returns the route of the notification tap that launched it, or null.
  ///
  /// Call once from `main()` before `runApp`. Idempotent, bounded wait, never throws, never prompts.
  Future<NotificationRoute?> initialize();

  /// Foreground notifications the app must show itself. Only Android emits; on iOS the OS shows them.
  Stream<ForegroundNotification> get onForeground;

  /// Routes of notification taps while the process runs. Taps that arrive before the first listener are buffered
  /// and delivered to it.
  Stream<NotificationRoute> get onOpened;

  /// Shows the OS prompt only while undecided ([AuthorizationStatus.notDetermined]), at most once per process, then
  /// logs the FCM token.
  ///
  /// Call after the first frame. Never throws.
  Future<void> requestPermission();
}

/// Whether this build receives push notifications.
///
/// The develop flavor talks to the Emulator Suite, which has no FCM, and the web app would need a messaging
/// service worker and a VAPID key.
bool isPushNotificationSupported({required Flavor flavor, required bool isWeb}) => !isWeb && flavor != Flavor.develop;

/// The [PushNotificationRepository] for this build. Unsupported builds (see [isPushNotificationSupported]) get one
/// that never touches the plugin.
PushNotificationRepository createPushNotificationRepository({required Flavor flavor, required Talker talker}) =>
    isPushNotificationSupported(flavor: flavor, isWeb: kIsWeb)
    ? FirebasePushNotificationRepository(talker: talker)
    : const _UnsupportedPushNotificationRepository();

/// How long [FirebasePushNotificationRepository.initialize] holds startup for the notification that launched the
/// app. A later answer is delivered on [PushNotificationRepository.onOpened] instead.
const _initialMessageWait = Duration(seconds: 1);

const _initialMessageFailure = 'Failed to read the notification that launched the app';

final class FirebasePushNotificationRepository implements PushNotificationRepository {
  /// [messaging], [onMessage], [onMessageOpenedApp] and [platform] default to the plugin and the running platform.
  /// Tests pass fakes because the plugin's streams are static.
  FirebasePushNotificationRepository({
    required this.talker,
    FirebaseMessaging? messaging,
    Stream<RemoteMessage>? onMessage,
    Stream<RemoteMessage>? onMessageOpenedApp,
    TargetPlatform? platform,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _onMessage = onMessage ?? FirebaseMessaging.onMessage,
       _onMessageOpenedApp = onMessageOpenedApp ?? FirebaseMessaging.onMessageOpenedApp,
       _platform = platform ?? defaultTargetPlatform;

  final Talker talker;
  final FirebaseMessaging _messaging;
  final Stream<RemoteMessage> _onMessage;
  final Stream<RemoteMessage> _onMessageOpenedApp;
  final TargetPlatform _platform;

  final _subscriptions = <StreamSubscription<Object?>>[];
  final _foreground = StreamController<ForegroundNotification>.broadcast();
  late final _opened = StreamController<NotificationRoute>.broadcast(onListen: _flushPendingRoutes);

  final _pendingRoutes = <NotificationRoute>[];

  /// FCM message IDs of the taps already handled. A launch tap can be reported both by `getInitialMessage` and by
  /// `onMessageOpenedApp`.
  final _handledMessageIds = <String>{};

  Future<NotificationRoute?>? _initialization;
  Future<void>? _permissionRequest;

  @override
  Stream<ForegroundNotification> get onForeground => _foreground.stream;

  @override
  Stream<NotificationRoute> get onOpened => _opened.stream;

  @override
  Future<NotificationRoute?> initialize() => _initialization ??= _initialize();

  Future<NotificationRoute?> _initialize() async {
    // プラグインはインスタンスの最初の呼び出しでネイティブからの通知を受け取り始め、静的な Stream は
    // broadcast で購読前のイベントを捨てる。起動直後のタップを逃さないよう、先に購読する。
    _subscriptions
      ..add(_onMessageOpenedApp.listen(_onTap, onError: _logStreamError))
      ..add(_onMessage.listen(_onForegroundMessage, onError: _logStreamError));
    if (_platform == TargetPlatform.iOS) {
      unawaited(
        _guard(
          () => _messaging.setForegroundNotificationPresentationOptions(alert: true, sound: true),
          'Failed to enable foreground notification banners',
        ),
      );
    }
    _listenForTokenRefresh();

    final initialMessage = await _readInitialMessage();
    final launchRoute = initialMessage == null ? null : _routeOfNewTap(initialMessage);
    if (launchRoute != null) {
      return launchRoute;
    }
    // 起動のタップが getInitialMessage ではなく onMessageOpenedApp で届いた場合も、起動時の遷移先にする
    // (プラグインの登録がシーンの接続より遅れた iOS など)。
    return _pendingRoutes.isEmpty ? null : _pendingRoutes.removeAt(0);
  }

  /// Waits at most [_initialMessageWait] for `getInitialMessage`. A later answer is handled like any tap.
  Future<RemoteMessage?> _readInitialMessage() async {
    final Future<RemoteMessage?> request;
    try {
      request = _messaging.getInitialMessage();
    } on Exception catch (error, stackTrace) {
      talker.handle(error, stackTrace, _initialMessageFailure);
      return null;
    }
    var waiting = true;
    return request
        .then<RemoteMessage?>(
          (message) {
            if (waiting || message == null) {
              return message;
            }
            _onTap(message);
            return null;
          },
          onError: (Object error, StackTrace stackTrace) {
            talker.handle(error, stackTrace, _initialMessageFailure);
            return null;
          },
        )
        .timeout(
          _initialMessageWait,
          onTimeout: () {
            waiting = false;
            talker.warning('No answer about the launching notification after $_initialMessageWait; starting normally');
            return null;
          },
        );
  }

  void _onTap(RemoteMessage message) {
    final route = _routeOfNewTap(message);
    if (route == null || _opened.isClosed) {
      return;
    }
    if (_opened.hasListener) {
      _opened.add(route);
    } else {
      _pendingRoutes.add(route);
    }
  }

  void _flushPendingRoutes() {
    _pendingRoutes.forEach(_opened.add);
    _pendingRoutes.clear();
  }

  NotificationRoute? _routeOfNewTap(RemoteMessage message) {
    final id = message.messageId;
    if (id != null && !_handledMessageIds.add(id)) {
      return null;
    }
    return _routeOf(message);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (_platform != TargetPlatform.android ||
        notification == null ||
        (notification.title == null && notification.body == null)) {
      return;
    }
    _foreground.add(
      ForegroundNotification(title: notification.title, body: notification.body, route: _routeOf(message)),
    );
  }

  /// The only reader of [RemoteMessage.data]. Logs a rejected value so that an operator's typo shows up in the log.
  NotificationRoute? _routeOf(RemoteMessage message) {
    final Object? raw = message.data[notificationRouteKey];
    if (raw == null) {
      return null;
    }
    final route = parseNotificationRoute(raw);
    if (route == null) {
      talker.warning('Ignoring the route "$raw" of notification ${message.messageId}');
    }
    return route;
  }

  void _listenForTokenRefresh() {
    try {
      _subscriptions.add(
        _messaging.onTokenRefresh.listen(
          (token) => talker.info('FCM registration token: $token'),
          onError: _logStreamError,
        ),
      );
    } on Exception catch (error, stackTrace) {
      talker.handle(error, stackTrace, 'Failed to listen for FCM registration tokens');
    }
  }

  @override
  Future<void> requestPermission() => _permissionRequest ??= _requestPermissionOnce();

  Future<void> _requestPermissionOnce() async {
    await _guard(() async {
      final settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.notDetermined) {
        return;
      }
      final answer = await _messaging.requestPermission(badge: false);
      talker.info('Notification permission: ${answer.authorizationStatus.name}');
    }, 'Failed to request the notification permission');
    await _guard(_logToken, 'Failed to read the FCM registration token');
  }

  /// On iOS, `getToken` throws until APNs has registered the device; the `onTokenRefresh` subscription logs the token
  /// once it is issued.
  Future<void> _logToken() async {
    if (_platform == TargetPlatform.iOS && await _messaging.getAPNSToken() == null) {
      talker.info('No APNs token yet; the FCM registration token is logged once it is issued');
      return;
    }
    talker.info('FCM registration token: ${await _messaging.getToken()}');
  }

  Future<void> _guard(Future<void> Function() action, String failure) async {
    try {
      await action();
    } on Exception catch (error, stackTrace) {
      talker.handle(error, stackTrace, failure);
    }
  }

  void _logStreamError(Object error, StackTrace stackTrace) =>
      talker.handle(error, stackTrace, 'Push notification stream failed');

  /// Cancels the plugin subscriptions and closes the streams.
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _foreground.close();
    await _opened.close();
  }
}

final class _UnsupportedPushNotificationRepository implements PushNotificationRepository {
  const _UnsupportedPushNotificationRepository();

  @override
  Future<NotificationRoute?> initialize() async => null;

  @override
  Stream<ForegroundNotification> get onForeground => const Stream.empty();

  @override
  Stream<NotificationRoute> get onOpened => const Stream.empty();

  @override
  Future<void> requestPermission() async {}
}
