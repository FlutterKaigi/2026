import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';

part 'quiz_question.freezed.dart';
part 'quiz_question.g.dart';

@JsonEnum()
enum QuizQuestionStatus { draft, open, closed, revealed }

@freezed
abstract class QuizQuestion with _$QuizQuestion {
  const QuizQuestion._();

  const factory QuizQuestion({
    required String id,
    required String sponsorId,
    required int order,
    required String title,
    @Default([]) List<String> options,
    @Default(180) int durationSeconds,
    required QuizQuestionStatus status,
    @FirestoreNullableDateTimeConverter() DateTime? openedAt,
    @FirestoreNullableDateTimeConverter() DateTime? closesAt,
    int? correctOptionIndex,
    String? explanation,
  }) = _QuizQuestion;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => _$QuizQuestionFromJson(json);

  bool get isNew => id.isEmpty;
}
