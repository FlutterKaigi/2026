// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuizQuestion _$QuizQuestionFromJson(Map<String, dynamic> json) =>
    _QuizQuestion(
      id: json['id'] as String,
      sponsorId: json['sponsorId'] as String,
      order: (json['order'] as num).toInt(),
      title: LocaleMap.fromJson(json['title'] as Map<String, dynamic>),
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => LocaleMap.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 180,
      status: $enumDecode(_$QuizQuestionStatusEnumMap, json['status']),
      openedAt: const FirestoreNullableDateTimeConverter().fromJson(
        json['openedAt'],
      ),
      closesAt: const FirestoreNullableDateTimeConverter().fromJson(
        json['closesAt'],
      ),
      correctOptionIndex: (json['correctOptionIndex'] as num?)?.toInt(),
      explanation: json['explanation'] == null
          ? null
          : LocaleMap.fromJson(json['explanation'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuizQuestionToJson(_QuizQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sponsorId': instance.sponsorId,
      'order': instance.order,
      'title': instance.title.toJson(),
      'options': instance.options.map((e) => e.toJson()).toList(),
      'durationSeconds': instance.durationSeconds,
      'status': _$QuizQuestionStatusEnumMap[instance.status]!,
      'openedAt': const FirestoreNullableDateTimeConverter().toJson(
        instance.openedAt,
      ),
      'closesAt': const FirestoreNullableDateTimeConverter().toJson(
        instance.closesAt,
      ),
      'correctOptionIndex': instance.correctOptionIndex,
      'explanation': instance.explanation?.toJson(),
    };

const _$QuizQuestionStatusEnumMap = {
  QuizQuestionStatus.draft: 'draft',
  QuizQuestionStatus.open: 'open',
  QuizQuestionStatus.closed: 'closed',
  QuizQuestionStatus.revealed: 'revealed',
};
