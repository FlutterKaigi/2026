import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Whether the conference-day event features (missions, quiz, support LT,
/// profile exchange, SNS post) are shown.
///
/// Backed by [RemoteConfigKeys.eventFeaturesEnabled]; watches
/// [remoteConfigUpdatesProvider] so consumers recompute when the flag changes
/// while the app is running.
final eventFeaturesEnabledProvider = Provider<bool>((ref) {
  ref.watch(remoteConfigUpdatesProvider);
  return ref.watch(remoteConfigRepositoryProvider).getBool(RemoteConfigKeys.eventFeaturesEnabled);
});
