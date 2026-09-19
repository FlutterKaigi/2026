/// The single self-reported category of the person in the posted photo.
enum SnsPostCompanion { staff, speaker, sponsor, firstTime, differentCountry }

/// One SNS photo post per attendee, stored at `snsPostRegistrations/{uid}`.
final class SnsPostRegistration {
  const SnsPostRegistration({
    required this.url,
    required this.companion,
    required this.updatedAt,
  });

  final String url;
  final SnsPostCompanion companion;
  final DateTime updatedAt;

  static const urlMaxLength = 2048;

  /// Accepts post links from any SNS, including independently hosted ones.
  /// Keep the shape and length limit in sync with Firestore rules/schema.
  static bool isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    return value.length <= urlMaxLength &&
        RegExp(r'^https?://[^/?#\s@]+[.][^/?#\s@]+/[^?#\s][^\s]*$').hasMatch(value) &&
        uri != null &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        uri.path.length > 1;
  }
}
