// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_answer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuizAnswer _$QuizAnswerFromJson(Map<String, dynamic> json) => _QuizAnswer(
  id: json['id'] as String,
  questionId: json['questionId'] as String,
  teamId: json['teamId'] as String,
  selectedOptionIndex: (json['selectedOptionIndex'] as num?)?.toInt(),
  answeredBy: json['answeredBy'] as String?,
  submittedAt: const FirestoreNullableDateTimeConverter().fromJson(
    json['submittedAt'],
  ),
  isCorrect: json['isCorrect'] as bool?,
);

Map<String, dynamic> _$QuizAnswerToJson(_QuizAnswer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'questionId': instance.questionId,
      'teamId': instance.teamId,
      'selectedOptionIndex': instance.selectedOptionIndex,
      'answeredBy': instance.answeredBy,
      'submittedAt': const FirestoreNullableDateTimeConverter().toJson(
        instance.submittedAt,
      ),
      'isCorrect': instance.isCorrect,
    };
