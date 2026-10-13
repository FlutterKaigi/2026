import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';

part 'quiz_participant.freezed.dart';
part 'quiz_participant.g.dart';

@freezed
abstract class QuizParticipant with _$QuizParticipant {
  const QuizParticipant._();

  const factory QuizParticipant({
    required String id,
    required String displayName,
    @FirestoreDateTimeConverter() required DateTime registeredAt,
    String? teamId,

    /// 会場の参加コードでチェックインした時刻。チーム選択にはチェックインが必要。
    @FirestoreNullableDateTimeConverter() DateTime? checkedInAt,
  }) = _QuizParticipant;

  factory QuizParticipant.fromJson(Map<String, dynamic> json) => _$QuizParticipantFromJson(json);
}
