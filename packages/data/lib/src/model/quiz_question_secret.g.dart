// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_question_secret.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuizQuestionSecret _$QuizQuestionSecretFromJson(Map<String, dynamic> json) =>
    _QuizQuestionSecret(
      correctOptionIndex: (json['correctOptionIndex'] as num).toInt(),
      explanation: json['explanation'] as String,
    );

Map<String, dynamic> _$QuizQuestionSecretToJson(_QuizQuestionSecret instance) =>
    <String, dynamic>{
      'correctOptionIndex': instance.correctOptionIndex,
      'explanation': instance.explanation,
    };
