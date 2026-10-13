import 'quiz_participant.dart';
import 'quiz_team.dart';

const quizTeamIds = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
];

/// 初出題前の表示用。確定チームの保存はサーバーが初出題と同時に行う。
List<QuizTeam> quizTeamsFromParticipants(List<QuizParticipant> participants, {bool includeEmpty = false}) => [
  for (final (index, id) in quizTeamIds.indexed)
    if (includeEmpty || participants.any((person) => person.teamId == id))
      QuizTeam(
        id: id,
        tableNumber: index + 1,
        name: id,
        memberUids: [
          for (final person in participants)
            if (person.teamId == id) person.id,
        ],
        members: [
          for (final person in participants)
            if (person.teamId == id) QuizTeamMember(uid: person.id, displayName: person.displayName),
        ],
      ),
];
