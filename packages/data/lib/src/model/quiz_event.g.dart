// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuizEvent _$QuizEventFromJson(Map<String, dynamic> json) => _QuizEvent(
  id: json['id'] as String,
  title: LocaleMap.fromJson(json['title'] as Map<String, dynamic>),
  status: $enumDecode(_$QuizEventStatusEnumMap, json['status']),
  currentQuestionId: json['currentQuestionId'] as String?,
  sponsorIds:
      (json['sponsorIds'] as List<dynamic>?)
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
  'currentQuestionId': instance.currentQuestionId,
  'sponsorIds': instance.sponsorIds,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
};

const _$QuizEventStatusEnumMap = {
  QuizEventStatus.registration: 'registration',
  QuizEventStatus.teamBuilding: 'teamBuilding',
  QuizEventStatus.inProgress: 'inProgress',
  QuizEventStatus.finished: 'finished',
};
