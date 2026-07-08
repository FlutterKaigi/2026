// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuizTeamMember _$QuizTeamMemberFromJson(Map<String, dynamic> json) =>
    _QuizTeamMember(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
    );

Map<String, dynamic> _$QuizTeamMemberToJson(_QuizTeamMember instance) =>
    <String, dynamic>{'uid': instance.uid, 'displayName': instance.displayName};

_QuizTeam _$QuizTeamFromJson(Map<String, dynamic> json) => _QuizTeam(
  id: json['id'] as String,
  tableNumber: (json['tableNumber'] as num).toInt(),
  name: json['name'] as String,
  memberUids:
      (json['memberUids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  members:
      (json['members'] as List<dynamic>?)
          ?.map((e) => QuizTeamMember.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  score: (json['score'] as num?)?.toInt() ?? 0,
  rank: (json['rank'] as num?)?.toInt(),
  perfectSponsorIds:
      (json['perfectSponsorIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$QuizTeamToJson(_QuizTeam instance) => <String, dynamic>{
  'id': instance.id,
  'tableNumber': instance.tableNumber,
  'name': instance.name,
  'memberUids': instance.memberUids,
  'members': instance.members.map((e) => e.toJson()).toList(),
  'score': instance.score,
  'rank': instance.rank,
  'perfectSponsorIds': instance.perfectSponsorIds,
};
