// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_News _$NewsFromJson(Map<String, dynamic> json) => _News(
  id: json['id'] as String,
  title: LocaleMap.fromJson(json['title'] as Map<String, dynamic>),
  url: LocaleMap.fromJson(json['url'] as Map<String, dynamic>),
  publishedAt: const FirestoreDateTimeConverter().fromJson(json['publishedAt']),
  createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$NewsToJson(_News instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title.toJson(),
  'url': instance.url.toJson(),
  'publishedAt': const FirestoreDateTimeConverter().toJson(
    instance.publishedAt,
  ),
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
};
