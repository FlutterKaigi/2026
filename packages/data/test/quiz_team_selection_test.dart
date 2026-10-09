import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unselected participants are excluded and table labels keep their alphabet order', () {
    final people = [
      QuizParticipant(id: 't', displayName: 'T member', registeredAt: DateTime.utc(2026), teamId: 'T'),
      QuizParticipant(id: 'a', displayName: 'A member', registeredAt: DateTime.utc(2026), teamId: 'A'),
      QuizParticipant(id: 'waiting', displayName: 'Waiting', registeredAt: DateTime.utc(2026)),
    ];
    final groups = quizTeamsFromParticipants(people);
    expect(groups.map((team) => team.name), ['A', 'T']);
    expect(groups.last.tableNumber, 20);
    expect(groups.first.members.single.uid, 'a');
    expect(quizTeamsFromParticipants(people, includeEmpty: true).length, 20);
  });

  test('legacy and future selection status decode safely', () {
    final data = {
      'id': 'event',
      'title': {'ja': 'Quiz', 'en': 'Quiz'},
      'status': 'registration',
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-01T00:00:00Z',
    };
    expect(QuizEvent.fromJson(data).teamSelectionStatus, QuizTeamSelectionStatus.notStarted);
    expect(
      QuizEvent.fromJson({...data, 'teamSelectionStatus': 'future'}).teamSelectionStatus,
      QuizTeamSelectionStatus.notStarted,
    );
  });
}
