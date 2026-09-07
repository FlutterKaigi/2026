import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';
import 'sns_link.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// Attendee profile stored at `users/{uid}`.
///
/// Profiles are shared with other signed-in attendees (profile exchange), so
/// this model deliberately carries no email or other account data — those
/// stay in Firebase Auth.
@freezed
abstract class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    /// Firebase Auth uid, which is also the document id.
    required String id,
    required String displayName,
    String? avatarUrl,

    /// ISO 3166-1 alpha-2 code, see `countries` in the data package.
    required String countryOrRegion,
    @Default([]) List<SnsLink> snsLinks,
    String? bio,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

  /// Upper bound on [displayName] length, enforced in Firestore rules too.
  static const displayNameMaxLength = 30;

  /// Upper bound on [bio] length, enforced in Firestore rules too.
  static const bioMaxLength = 300;

  /// Upper bound on the number of [snsLinks], enforced in Firestore rules too.
  static const snsLinksMaxCount = 10;
}
