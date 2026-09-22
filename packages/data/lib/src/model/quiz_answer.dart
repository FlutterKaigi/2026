import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';

part 'quiz_answer.freezed.dart';
part 'quiz_answer.g.dart';

@freezed
abstract class QuizAnswer with _$QuizAnswer {
  const QuizAnswer._();

  const factory QuizAnswer({
    required String id,
    required String questionId,
    required String teamId,
    int? selectedOptionIndex,
    String? answeredBy,
    @FirestoreNullableDateTimeConverter() DateTime? submittedAt,
    bool? isCorrect,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(false) bool isFromCache,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(false) bool hasPendingWrites,
  }) = _QuizAnswer;

  factory QuizAnswer.fromJson(Map<String, dynamic> json) => _$QuizAnswerFromJson(json);
}
