import 'package:freezed_annotation/freezed_annotation.dart';

import 'locale_map.dart';

part 'quiz_question_secret.freezed.dart';
part 'quiz_question_secret.g.dart';

/// クイズ問題の正解と解説。参加者からは read できず、運営（管理者）のみ
/// アクセスできる `questions/{questionId}/secret/answer` ドキュメントに対応する。
@freezed
abstract class QuizQuestionSecret with _$QuizQuestionSecret {
  const QuizQuestionSecret._();

  const factory QuizQuestionSecret({
    required int correctOptionIndex,

    /// 解説（日英）。正解発表時に question 側へコピーされる。
    required LocaleMap explanation,
  }) = _QuizQuestionSecret;

  factory QuizQuestionSecret.fromJson(Map<String, dynamic> json) => _$QuizQuestionSecretFromJson(json);
}
