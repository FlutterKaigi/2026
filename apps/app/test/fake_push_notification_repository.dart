import 'dart:async';

import 'package:app/feature/push_notification/data/notification_route.dart';
import 'package:app/feature/push_notification/data/push_notification_repository.dart';

final class FakePushNotificationRepository implements PushNotificationRepository {
  final _foreground = StreamController<ForegroundNotification>.broadcast();
  final _opened = StreamController<NotificationRoute>.broadcast();
  int permissionRequestCount = 0;

  bool get hasListener => _foreground.hasListener || _opened.hasListener;

  @override
  Stream<ForegroundNotification> get onForeground => _foreground.stream;

  @override
  Stream<NotificationRoute> get onOpened => _opened.stream;

  @override
  Future<NotificationRoute?> initialize() async => null;

  @override
  Future<void> requestPermission() async {
    permissionRequestCount++;
  }

  void receive(ForegroundNotification notification) => _foreground.add(notification);

  void open(NotificationRoute route) => _opened.add(route);

  void dispose() {
    unawaited(_foreground.close());
    unawaited(_opened.close());
  }
}
