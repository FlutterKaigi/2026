import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_question_secret.freezed.dart';
part 'quiz_question_secret.g.dart';

/// クイズ問題の正解と解説。参加者からは read できず、運営（管理者）のみ
/// アクセスできる `questions/{questionId}/secret/answer` ドキュメントに対応する。
@freezed
abstract class QuizQuestionSecret with _$QuizQuestionSecret {
  const QuizQuestionSecret._();

  const factory QuizQuestionSecret({
    required int correctOptionIndex,
    required String explanation,
  }) = _QuizQuestionSecret;

  factory QuizQuestionSecret.fromJson(Map<String, dynamic> json) => _$QuizQuestionSecretFromJson(json);
}
