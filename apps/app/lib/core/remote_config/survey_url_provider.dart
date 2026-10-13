import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The survey destination, or null while it is unset or invalid.
///
/// Recomputes after activation so publishing or clearing the URL also updates
/// an already open event overview. Fetch failures keep the last active value.
final surveyUrlProvider = Provider<Uri?>((ref) {
  ref.watch(remoteConfigUpdatesProvider);
  final value = ref.watch(remoteConfigRepositoryProvider).getString(RemoteConfigKeys.surveyUrl).trim();
  if (value.contains(RegExp(r'[\s\x00-\x1f\x7f]'))) {
    return null;
  }
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      uri.host.contains('%') ||
      uri.userInfo.isNotEmpty ||
      uri.port < 1 ||
      uri.port > 65535) {
    return null;
  }
  return uri;
});
