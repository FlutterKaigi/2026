import 'package:app/feature/push_notification/data/push_notification_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides the app-wide [PushNotificationRepository].
///
/// Initialized during startup and injected via [ProviderScope.overrides] in `main()`, because its initialization
/// decides the route the app starts on.
final pushNotificationRepositoryProvider = Provider<PushNotificationRepository>(
  (ref) => throw UnimplementedError(
    'pushNotificationRepositoryProvider must be overridden in main()',
  ),
);
