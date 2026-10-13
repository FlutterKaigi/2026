import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';
import 'locale_map.dart';

part 'quiz_event.freezed.dart';
part 'quiz_event.g.dart';

@JsonEnum()
enum QuizEventStatus {
  /// 非公開。参加者アプリのイベント一覧に表示されない（運営のみ閲覧可）。
  draft,

  /// 公開済みだが参加受付は未開始。アプリには「開催準備中」として表示される。
  published,

  /// 参加受付中。コードなしで参加表明できる。
  registration,

  /// 参加受付終了。新規の参加登録はできない。
  entryClosed,

  /// 出題進行中。
  inProgress,

  /// 結果確定済み。
  finished,
}

@JsonEnum()
enum QuizTeamSelectionStatus { notStarted, open, closed }

@freezed
abstract class QuizEvent with _$QuizEvent {
  const QuizEvent._();

  const factory QuizEvent({
    required String id,
    required LocaleMap title,
    required QuizEventStatus status,
    @JsonKey(unknownEnumValue: QuizTeamSelectionStatus.notStarted)
    @Default(QuizTeamSelectionStatus.notStarted)
    QuizTeamSelectionStatus teamSelectionStatus,

    /// 参加者アプリに公開中かどうか。`status != draft` と常に同値になるよう
    /// 遷移時に更新する。アプリの一覧クエリはこのフラグの等価条件で絞り込む
    /// （ルールが単純な等価条件しかクエリから証明できないため）。
    @Default(false) bool isPublic,
    String? currentQuestionId,
    @Default([]) List<String> sponsorIds,

    /// 参加人数の上限。到達すると新規登録を締め切る。
    @Default(80) int capacity,

    /// 旧大会の設定を読み取るために保持する。新規のチーム名は A〜T 固定。
    @Default([]) List<String> teamNamePool,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
  }) = _QuizEvent;

  factory QuizEvent.fromJson(Map<String, dynamic> json) => _$QuizEventFromJson(json);

  bool get isNew => id.isEmpty;
}
