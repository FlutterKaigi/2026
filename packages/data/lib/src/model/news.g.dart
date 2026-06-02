// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_News _$NewsFromJson(Map<String, dynamic> json) => _News(
  id: json['id'] as String,
  title: json['title'] as String,
  status: $enumDecode(_$NewsStatusEnumMap, json['status']),
  startsAt: const FirestoreDateTimeConverter().fromJson(json['startsAt']),
  createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
  url: const FirestoreNullableUriConverter().fromJson(json['url']),
  endsAt: const FirestoreNullableDateTimeConverter().fromJson(json['endsAt']),
);

Map<String, dynamic> _$NewsToJson(_News instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'status': _$NewsStatusEnumMap[instance.status]!,
  'startsAt': const FirestoreDateTimeConverter().toJson(instance.startsAt),
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
  'url': const FirestoreNullableUriConverter().toJson(instance.url),
  'endsAt': const FirestoreNullableDateTimeConverter().toJson(instance.endsAt),
};

const _$NewsStatusEnumMap = {
  NewsStatus.draft: 'draft',
  NewsStatus.published: 'published',
  NewsStatus.archived: 'archived',
};
