import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/quiz_team.dart';

abstract interface class QuizTeamRepository {
  Stream<List<QuizTeam>> watchAll(String eventId);
  Stream<QuizTeam?> watchById(String eventId, String teamId);

  /// チーム名を変更する（運営用）。
  Future<void> updateName(String eventId, String teamId, String name);
}

final class FirestoreQuizTeamRepository implements QuizTeamRepository {
  FirestoreQuizTeamRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String eventId) =>
      _firestore.collection('quizEvents').doc(eventId).collection('teams');

  @override
  Stream<List<QuizTeam>> watchAll(String eventId) {
    return _collection(eventId)
        .orderBy('tableNumber')
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) QuizTeam.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }

  @override
  Stream<QuizTeam?> watchById(String eventId, String teamId) {
    return _collection(eventId).doc(teamId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return QuizTeam.fromJson(<String, dynamic>{...data, 'id': snapshot.id});
    });
  }

  @override
  Future<void> updateName(String eventId, String teamId, String name) {
    return _collection(eventId).doc(teamId).update(<String, dynamic>{'name': name});
  }
}
