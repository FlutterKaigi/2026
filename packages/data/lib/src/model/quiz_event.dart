import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';
import 'locale_map.dart';

part 'quiz_event.freezed.dart';
part 'quiz_event.g.dart';

@JsonEnum()
enum QuizEventStatus { registration, teamBuilding, inProgress, finished }

@freezed
abstract class QuizEvent with _$QuizEvent {
  const QuizEvent._();

  const factory QuizEvent({
    required String id,
    required LocaleMap title,
    required QuizEventStatus status,
    String? currentQuestionId,
    @Default([]) List<String> sponsorIds,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
  }) = _QuizEvent;

  factory QuizEvent.fromJson(Map<String, dynamic> json) => _$QuizEventFromJson(json);

  bool get isNew => id.isEmpty;
}
