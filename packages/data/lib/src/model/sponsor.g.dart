// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sponsor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Sponsor _$SponsorFromJson(Map<String, dynamic> json) => _Sponsor(
  id: json['id'] as String,
  name: LocaleMap.fromJson(json['name'] as Map<String, dynamic>),
  nameKana: json['nameKana'] as String?,
  description: LocaleMap.fromJson(json['description'] as Map<String, dynamic>),
  logoUrl: json['logoUrl'] as String,
  xUrl: json['xUrl'] as String?,
  websiteUrl: json['websiteUrl'] as String?,
  recruitUrl: json['recruitUrl'] as String?,
  jobBoardUrl: json['jobBoardUrl'] as String?,
  createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$SponsorToJson(_Sponsor instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name.toJson(),
  'nameKana': instance.nameKana,
  'description': instance.description.toJson(),
  'logoUrl': instance.logoUrl,
  'xUrl': instance.xUrl,
  'websiteUrl': instance.websiteUrl,
  'recruitUrl': instance.recruitUrl,
  'jobBoardUrl': instance.jobBoardUrl,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
};
