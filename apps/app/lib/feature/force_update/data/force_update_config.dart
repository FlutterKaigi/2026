import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Forced-update policy published through Remote Config as a JSON string.
///
/// Shape:
/// ```json
/// {
///   "minimum_version": {"ios": "1.2.0", "android": "1.2.0"},
///   "store_urls": {"ios": "https://...", "android": "https://..."},
///   "message": {"ja": "...", "en": "..."}
/// }
/// ```
///
/// Parsing fails open: malformed JSON, missing keys and values of an
/// unexpected type all yield [ForceUpdateConfig.none], which forces no update,
/// so a broken policy can never lock attendees out of the app.
@immutable
final class ForceUpdateConfig {
  const ForceUpdateConfig({
    required this.minimumVersions,
    required this.storeUrls,
    required this.messages,
  });

  /// Reads the `force_update` parameter value. Does not throw.
  factory ForceUpdateConfig.parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return none;
    }
    if (decoded is! Map<String, Object?>) {
      return none;
    }
    return ForceUpdateConfig(
      minimumVersions: _stringMap(decoded['minimum_version']),
      storeUrls: _stringMap(decoded['store_urls']),
      messages: _stringMap(decoded['message']),
    );
  }

  /// Policy used whenever nothing usable could be parsed.
  static const none = ForceUpdateConfig(minimumVersions: {}, storeUrls: {}, messages: {});

  /// Minimum required app version per platform key (`ios` / `android`).
  final Map<String, String> minimumVersions;

  /// Store page per platform key (`ios` / `android`).
  final Map<String, String> storeUrls;

  /// Update prompt body per language code (`ja` / `en`).
  final Map<String, String> messages;

  /// The minimum version for [platform], or an empty string when the policy
  /// says nothing about it (including on platforms with no store).
  String minimumVersionFor(TargetPlatform platform) => minimumVersions[forceUpdatePlatformKey(platform)] ?? '';

  /// The store URL for [platform], or an empty string when unconfigured.
  String storeUrlFor(TargetPlatform platform) => storeUrls[forceUpdatePlatformKey(platform)] ?? '';
}

/// The policy key for [platform], or null on platforms the app is not
/// distributed through a store on.
String? forceUpdatePlatformKey(TargetPlatform platform) => switch (platform) {
  TargetPlatform.iOS => 'ios',
  TargetPlatform.android => 'android',
  _ => null,
};

/// Keeps the `String` entries of [value] and drops everything else.
Map<String, String> _stringMap(Object? value) {
  if (value is! Map<String, Object?>) {
    return const {};
  }
  return Map.unmodifiable(<String, String>{
    for (final entry in value.entries)
      if (entry.value is String) entry.key: entry.value! as String,
  });
}
