// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Session _$SessionFromJson(Map<String, dynamic> json) => _Session(
  id: json['id'] as String,
  title: LocaleMap.fromJson(json['title'] as Map<String, dynamic>),
  description: LocaleMap.fromJson(json['description'] as Map<String, dynamic>),
  primaryLocale: json['primaryLocale'] as String,
  startsAt: const FirestoreDateTimeConverter().fromJson(json['startsAt']),
  endsAt: const FirestoreDateTimeConverter().fromJson(json['endsAt']),
  venueId: json['venueId'] as String,
  speakerIds:
      (json['speakerIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  isLightningTalk: json['isLightningTalk'] as bool? ?? false,
  isBeginnersLightningTalk: json['isBeginnersLightningTalk'] as bool? ?? false,
  isHandsOn: json['isHandsOn'] as bool? ?? false,
  sessionizeUrl: json['sessionizeUrl'] as String?,
  createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$SessionToJson(_Session instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title.toJson(),
  'description': instance.description.toJson(),
  'primaryLocale': instance.primaryLocale,
  'startsAt': const FirestoreDateTimeConverter().toJson(instance.startsAt),
  'endsAt': const FirestoreDateTimeConverter().toJson(instance.endsAt),
  'venueId': instance.venueId,
  'speakerIds': instance.speakerIds,
  'isLightningTalk': instance.isLightningTalk,
  'isBeginnersLightningTalk': instance.isBeginnersLightningTalk,
  'isHandsOn': instance.isHandsOn,
  'sessionizeUrl': instance.sessionizeUrl,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
};
