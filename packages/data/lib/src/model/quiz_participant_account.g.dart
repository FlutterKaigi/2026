// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_participant_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuizParticipantAccount _$QuizParticipantAccountFromJson(
  Map<String, dynamic> json,
) => _QuizParticipantAccount(
  uid: json['uid'] as String,
  signInProvider: json['signInProvider'] as String,
  linkedAt: const FirestoreDateTimeConverter().fromJson(json['linkedAt']),
  email: json['email'] as String?,
  accountName: json['accountName'] as String?,
  photoUrl: json['photoUrl'] as String?,
);

Map<String, dynamic> _$QuizParticipantAccountToJson(
  _QuizParticipantAccount instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'signInProvider': instance.signInProvider,
  'linkedAt': const FirestoreDateTimeConverter().toJson(instance.linkedAt),
  'email': instance.email,
  'accountName': instance.accountName,
  'photoUrl': instance.photoUrl,
};
