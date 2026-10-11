import 'package:flutter/foundation.dart';

/// The custom-data key whose value is the in-app path a tapped notification opens, such as `/news` or
/// `/sessions/<id>`. Operators set it in the Firebase console.
const notificationRouteKey = 'route';

/// An in-app location carried by a notification.
///
/// Instances only come from [parseNotificationRoute], so [location] is always a path a broadcast may open.
@immutable
final class NotificationRoute {
  const NotificationRoute._(this.location);

  /// Path only, without scheme, authority, query or fragment.
  final Uri location;

  @override
  bool operator ==(Object other) => other is NotificationRoute && other.location == location;

  @override
  int get hashCode => location.hashCode;

  @override
  String toString() => 'NotificationRoute(${location.path})';
}

/// Parses the value of [notificationRouteKey], returning `null` for anything a notification must not open.
/// Never throws.
///
/// Accepts a string that, after trimming, is an absolute path without scheme, authority, query, fragment or empty
/// segments. `Uri` removes dot segments while parsing, so the path that is checked is the path that is opened.
///
/// Invariant: a notification goes to every attendee, so it never opens a link that acts on the attendee's behalf
/// when opened: `/x/<token>` (profile exchange), `/s/<token>` (stamp rally) and `/account/support-lt/<code>`
/// (attendance registration). A new route that acts when opened must be rejected here too.
NotificationRoute? parseNotificationRoute(Object? raw) {
  if (raw is! String) {
    return null;
  }
  final uri = Uri.tryParse(raw.trim());
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasQuery ||
      uri.hasFragment ||
      !uri.path.startsWith('/')) {
    return null;
  }
  final List<String> segments;
  try {
    // Uri.tryParse accepts percent escapes whose bytes are not valid UTF-8.
    segments = uri.pathSegments;
  } on FormatException {
    return null;
  }
  if (segments.any((segment) => segment.isEmpty) || _actsWhenOpened(segments)) {
    return null;
  }
  return NotificationRoute._(Uri(path: uri.path));
}

bool _actsWhenOpened(List<String> segments) => switch (segments) {
  ['x' || 's', ...] || ['account', 'support-lt', _, ...] => true,
  _ => false,
};
