import 'package:data/data.dart';

/// Evaluates the current profiles of distinct people in the exchange list.
/// Deleted/missing profiles and the attendee themself never count.
final class ProfileExchangeProgress {
  const ProfileExchangeProgress({required this.count, required this.hasDifferentCountry, required this.hasProfile});

  factory ProfileExchangeProgress.evaluate({
    required String uid,
    required UserProfile? profile,
    required Iterable<UserProfile?> exchangedProfiles,
  }) {
    final others = <String, UserProfile>{
      for (final other in exchangedProfiles)
        if (other != null && other.id != uid) other.id: other,
    };
    final country = profile?.countryOrRegion;
    return ProfileExchangeProgress(
      count: others.length,
      hasProfile: profile != null,
      hasDifferentCountry:
          country != null &&
          findCountry(country) != null &&
          others.values.any(
            (other) => findCountry(other.countryOrRegion) != null && other.countryOrRegion != country,
          ),
    );
  }

  final int count;
  final bool hasDifferentCountry;
  final bool hasProfile;

  static const requiredCount = 3;

  bool get hasRequiredCount => count >= requiredCount;

  bool get isComplete => hasProfile && hasRequiredCount && hasDifferentCountry;
}
