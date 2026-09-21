import 'package:app/feature/force_update/data/force_update_config.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:pub_semver/pub_semver.dart';

/// Result of the forced-update check for the running build.
@immutable
final class ForceUpdateState {
  const ForceUpdateState({
    this.isUpdateRequired = false,
    this.storeUrl = '',
    this.messages = const {},
  });

  /// The state every failure path degrades to.
  static const notRequired = ForceUpdateState();

  /// Whether the running version is below the published minimum.
  final bool isUpdateRequired;

  /// Store page for the running platform; empty when unconfigured.
  final String storeUrl;

  /// Remote prompt body per language code, as published.
  final Map<String, String> messages;

  /// The remote message for [languageCode], or null when the policy carries
  /// none for it. Callers fall back to the bundled translation.
  String? messageFor(String languageCode) {
    final message = messages[languageCode];
    return message == null || message.isEmpty ? null : message;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForceUpdateState &&
          other.isUpdateRequired == isUpdateRequired &&
          other.storeUrl == storeUrl &&
          const MapEquality<String, String>().equals(other.messages, messages);

  @override
  int get hashCode => Object.hash(
    isUpdateRequired,
    storeUrl,
    const MapEquality<String, String>().hash(messages),
  );
}

/// Applies [config] to the running build.
///
/// The web build is never forced to update because it always serves the
/// deployed version, and platforms without a store key are treated the same
/// way.
ForceUpdateState evaluateForceUpdate({
  required ForceUpdateConfig config,
  required String currentVersion,
  required bool isWeb,
  required TargetPlatform platform,
}) {
  if (isWeb || forceUpdatePlatformKey(platform) == null) {
    return ForceUpdateState.notRequired;
  }
  if (!isUpdateRequired(
    currentVersion: currentVersion,
    minimumVersion: config.minimumVersionFor(platform),
  )) {
    return ForceUpdateState.notRequired;
  }
  return ForceUpdateState(
    isUpdateRequired: true,
    storeUrl: config.storeUrlFor(platform),
    messages: config.messages,
  );
}

/// Whether [currentVersion] is older than [minimumVersion].
///
/// Build numbers are ignored: only the `version` part is compared. Fails open,
/// so a version string neither side can parse never forces an update.
bool isUpdateRequired({required String currentVersion, required String minimumVersion}) {
  try {
    return Version.parse(currentVersion) < Version.parse(minimumVersion);
  } on FormatException {
    return false;
  }
}
