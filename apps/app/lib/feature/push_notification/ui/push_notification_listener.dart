import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/push_notification/data/notification_route.dart';
import 'package:app/feature/push_notification/data/push_notification_provider.dart';
import 'package:app/feature/push_notification/data/push_notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Shows foreground notifications, opens tapped ones, and asks for the notification permission after the first
/// frame.
///
/// Inserted from `MaterialApp.builder`, below the app's [ScaffoldMessenger] and outside its Navigator, so it serves
/// every route.
class PushNotificationListener extends HookConsumerWidget {
  const PushNotificationListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pushNotifications = ref.watch(pushNotificationRepositoryProvider);
    useEffect(() {
      var disposed = false;
      final foreground = pushNotifications.onForeground.listen((notification) {
        if (context.mounted) {
          _show(context, ref, notification);
        }
      });
      final opened = pushNotifications.onOpened.listen((route) => _open(ref, route));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!disposed) {
          unawaited(pushNotifications.requestPermission());
        }
      });
      return () {
        disposed = true;
        unawaited(foreground.cancel());
        unawaited(opened.cancel());
      };
    }, [pushNotifications]);
    return child;
  }

  void _show(BuildContext context, WidgetRef ref, ForegroundNotification notification) {
    final route = notification.route;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.title case final title?)
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (notification.body case final body?) Text(body),
            ],
          ),
          action: route == null
              ? null
              : SnackBarAction(
                  label: Translations.of(context).pushNotification.open,
                  onPressed: () => _open(ref, route),
                ),
          showCloseIcon: true,
          duration: const Duration(seconds: 10),
          // アクション付きの SnackBar は既定では自動で閉じず、他の画面の SnackBar を待たせ続ける。
          persist: false,
        ),
      );
  }

  /// `go`, as go_router does for platform deep links: the route's own parents become the back stack and `redirect`
  /// still applies.
  void _open(WidgetRef ref, NotificationRoute route) => ref.read(routerProvider).go(route.location.toString());
}
