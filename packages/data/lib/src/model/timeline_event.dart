import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';
import 'locale_map.dart';

part 'timeline_event.freezed.dart';
part 'timeline_event.g.dart';

@freezed
abstract class TimelineEvent with _$TimelineEvent {
  const TimelineEvent._();

  const factory TimelineEvent({
    required String id,
    required LocaleMap title,
    @FirestoreDateTimeConverter() required DateTime startsAt,
    @FirestoreNullableDateTimeConverter() DateTime? endsAt,
    String? venueId,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
  }) = _TimelineEvent;

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => _$TimelineEventFromJson(json);

  bool get isNew => id.isEmpty;
}
