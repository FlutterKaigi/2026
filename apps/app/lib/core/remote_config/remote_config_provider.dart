import 'package:app/core/remote_config/remote_config_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides the app-wide [RemoteConfigRepository].
///
/// Initialized during startup and injected via [ProviderScope.overrides] in
/// `main()`, so flags can be read synchronously.
final remoteConfigRepositoryProvider = Provider<RemoteConfigRepository>(
  (ref) => throw UnimplementedError(
    'remoteConfigRepositoryProvider must be overridden in main()',
  ),
);

/// Emits an increasing revision every time Remote Config values are activated.
///
/// Providers that expose a flag `ref.watch` this so they are recomputed on
/// update. It counts instead of emitting `void` because two consecutive
/// `AsyncData<void>` values compare equal and would not notify listeners.
final remoteConfigUpdatesProvider = StreamProvider<int>((ref) {
  var revision = 0;
  return ref.watch(remoteConfigRepositoryProvider).onUpdated.map((_) => ++revision);
});
