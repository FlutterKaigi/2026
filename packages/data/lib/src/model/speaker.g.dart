// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speaker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Speaker _$SpeakerFromJson(Map<String, dynamic> json) => _Speaker(
  id: json['id'] as String,
  name: json['name'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  xId: json['xId'] as String?,
  bio: json['bio'] as String?,
  createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$SpeakerToJson(_Speaker instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatarUrl': instance.avatarUrl,
  'xId': instance.xId,
  'bio': instance.bio,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
};
