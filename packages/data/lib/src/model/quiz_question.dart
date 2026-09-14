import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';
import 'locale_map.dart';

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

    /// 問題文（日英）。参加者アプリでは端末ロケールで出し分ける。
    required LocaleMap title,

    /// 選択肢（日英）。並び順が回答の index に対応する。
    @Default([]) List<LocaleMap> options,
    @Default(180) int durationSeconds,
    required QuizQuestionStatus status,
    @FirestoreNullableDateTimeConverter() DateTime? openedAt,
    @FirestoreNullableDateTimeConverter() DateTime? closesAt,
    int? correctOptionIndex,

    /// 解説（日英）。正解発表時に secret からコピーされる。
    LocaleMap? explanation,
  }) = _QuizQuestion;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => _$QuizQuestionFromJson(json);

  bool get isNew => id.isEmpty;
}
