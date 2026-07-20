/// Venue ids are lowercase slugs (e.g. `hall-a`), mirroring the ingest-side
/// room id rule enforced by the captions server.
final _venueIdPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');

/// Extracts a caption venue id from a scanned QR payload.
///
/// Accepts a bare venue id (`hall-a`), a URL whose path contains a `captions`
/// segment followed by the venue id (`https://2026.flutterkaigi.jp/captions/hall-a`),
/// or the app deep link form (`flutterkaigi2026://captions/hall-a`). Returns
/// `null` when the payload does not identify a venue.
String? parseCaptionTarget(String rawValue) {
  final value = rawValue.trim();
  if (value.isEmpty) {
    return null;
  }

  if (_venueIdPattern.hasMatch(value)) {
    return value;
  }

  final uri = Uri.tryParse(value);
  if (uri == null) {
    return null;
  }
  final segments = [
    // In `flutterkaigi2026://captions/hall-a` the `captions` segment parses as
    // the URI host; fold it back into the path for a single lookup.
    if (uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments.where((s) => s.isNotEmpty),
  ];
  final captionsIndex = segments.indexOf('captions');
  if (captionsIndex < 0 || captionsIndex + 1 >= segments.length) {
    return null;
  }

  final candidate = segments[captionsIndex + 1];
  return _venueIdPattern.hasMatch(candidate) ? candidate : null;
}
