// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  countryOrRegion: json['countryOrRegion'] as String,
  snsLinks:
      (json['snsLinks'] as List<dynamic>?)?.map((e) => SnsLink.fromJson(e as Map<String, dynamic>)).toList() ??
      const [],
  bio: json['bio'] as String?,
  createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$UserProfileToJson(
  _UserProfile instance,
) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
  'countryOrRegion': instance.countryOrRegion,
  'snsLinks': instance.snsLinks.map((e) => e.toJson()).toList(),
  'bio': instance.bio,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
};
