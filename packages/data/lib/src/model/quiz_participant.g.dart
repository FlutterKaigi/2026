// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuizParticipant _$QuizParticipantFromJson(Map<String, dynamic> json) => _QuizParticipant(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  registeredAt: const FirestoreDateTimeConverter().fromJson(
    json['registeredAt'],
  ),
  teamId: json['teamId'] as String?,
  checkedInAt: const FirestoreNullableDateTimeConverter().fromJson(
    json['checkedInAt'],
  ),
);

Map<String, dynamic> _$QuizParticipantToJson(_QuizParticipant instance) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'registeredAt': const FirestoreDateTimeConverter().toJson(
    instance.registeredAt,
  ),
  'teamId': instance.teamId,
  'checkedInAt': const FirestoreNullableDateTimeConverter().toJson(
    instance.checkedInAt,
  ),
};
