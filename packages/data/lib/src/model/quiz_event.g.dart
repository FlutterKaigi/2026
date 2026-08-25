// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuizEvent _$QuizEventFromJson(Map<String, dynamic> json) => _QuizEvent(
  id: json['id'] as String,
  title: LocaleMap.fromJson(json['title'] as Map<String, dynamic>),
  status: $enumDecode(_$QuizEventStatusEnumMap, json['status']),
  isPublic: json['isPublic'] as bool? ?? false,
  currentQuestionId: json['currentQuestionId'] as String?,
  sponsorIds:
      (json['sponsorIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  capacity: (json['capacity'] as num?)?.toInt() ?? 80,
  teamNamePool:
      (json['teamNamePool'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$QuizEventToJson(
  _QuizEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title.toJson(),
  'status': _$QuizEventStatusEnumMap[instance.status]!,
  'isPublic': instance.isPublic,
  'currentQuestionId': instance.currentQuestionId,
  'sponsorIds': instance.sponsorIds,
  'capacity': instance.capacity,
  'teamNamePool': instance.teamNamePool,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
};

const _$QuizEventStatusEnumMap = {
  QuizEventStatus.draft: 'draft',
  QuizEventStatus.published: 'published',
  QuizEventStatus.registration: 'registration',
  QuizEventStatus.entryClosed: 'entryClosed',
  QuizEventStatus.inProgress: 'inProgress',
  QuizEventStatus.finished: 'finished',
};
