// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TimelineEvent _$TimelineEventFromJson(Map<String, dynamic> json) =>
    _TimelineEvent(
      id: json['id'] as String,
      title: LocaleMap.fromJson(json['title'] as Map<String, dynamic>),
      startsAt: const FirestoreDateTimeConverter().fromJson(json['startsAt']),
      endsAt: const FirestoreNullableDateTimeConverter().fromJson(
        json['endsAt'],
      ),
      venueId: json['venueId'] as String?,
      createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
      updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$TimelineEventToJson(
  _TimelineEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title.toJson(),
  'startsAt': const FirestoreDateTimeConverter().toJson(instance.startsAt),
  'endsAt': const FirestoreNullableDateTimeConverter().toJson(instance.endsAt),
  'venueId': instance.venueId,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
};
