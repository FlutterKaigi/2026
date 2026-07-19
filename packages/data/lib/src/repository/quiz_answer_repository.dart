import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/quiz_answer.dart';

abstract interface class QuizAnswerRepository {
  /// 自チームの回答（`answers/{questionId}_{teamId}`）を購読する。
  /// 出題前で未作成の間は `null` を流す。
  Stream<QuizAnswer?> watchByQuestionAndTeam(String eventId, String questionId, String teamId);

  /// 選択肢を送信する。ドキュメントは出題時に運営が事前作成済みのため、
  /// ここでは `selectedOptionIndex` / `answeredBy` / `submittedAt` のみを update する。
  Future<void> submit(
    String eventId,
    String questionId,
    String teamId, {
    required int selectedOptionIndex,
    required String uid,
  });

  /// 当該問題の全チームの回答を購読する（運営用）。
  Stream<List<QuizAnswer>> watchByQuestion(String eventId, String questionId);
}

final class FirestoreQuizAnswerRepository implements QuizAnswerRepository {
  FirestoreQuizAnswerRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String eventId) =>
      _firestore.collection('quizEvents').doc(eventId).collection('answers');

  @override
  Stream<QuizAnswer?> watchByQuestionAndTeam(String eventId, String questionId, String teamId) {
    return _collection(eventId).doc('${questionId}_$teamId').snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return QuizAnswer.fromJson(<String, dynamic>{...data, 'id': snapshot.id});
    });
  }

  @override
  Future<void> submit(
    String eventId,
    String questionId,
    String teamId, {
    required int selectedOptionIndex,
    required String uid,
  }) {
    return _collection(eventId).doc('${questionId}_$teamId').update(<String, dynamic>{
      'selectedOptionIndex': selectedOptionIndex,
      'answeredBy': uid,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<QuizAnswer>> watchByQuestion(String eventId, String questionId) {
    return _collection(eventId)
        .where('questionId', isEqualTo: questionId)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) QuizAnswer.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }
}
