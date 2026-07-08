import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_team.freezed.dart';
part 'quiz_team.g.dart';

@freezed
abstract class QuizTeamMember with _$QuizTeamMember {
  const QuizTeamMember._();

  const factory QuizTeamMember({
    required String uid,
    required String displayName,
  }) = _QuizTeamMember;

  factory QuizTeamMember.fromJson(Map<String, dynamic> json) => _$QuizTeamMemberFromJson(json);
}

@freezed
abstract class QuizTeam with _$QuizTeam {
  const QuizTeam._();

  const factory QuizTeam({
    required String id,
    required int tableNumber,
    required String name,
    @Default([]) List<String> memberUids,
    @Default([]) List<QuizTeamMember> members,
    @Default(0) int score,
    int? rank,
    @Default([]) List<String> perfectSponsorIds,
  }) = _QuizTeam;

  factory QuizTeam.fromJson(Map<String, dynamic> json) => _$QuizTeamFromJson(json);
}
