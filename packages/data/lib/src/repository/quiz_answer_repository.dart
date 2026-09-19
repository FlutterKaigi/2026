import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../model/quiz_answer.dart';

abstract interface class QuizAnswerRepository {
  /// 自チームの回答（`answers/{questionId}_{teamId}`）を購読する。
  /// 出題前で未作成の間は `null` を流す。
  Stream<QuizAnswer?> watchByQuestionAndTeam(String eventId, String questionId, String teamId);

  /// オンラインのサーバーに送信し、受理された場合にだけ成功する。
  /// Firestore のオフライン書き込みキューには保存しない。本人情報・締切はサーバーが検証する。
  Future<void> submit(
    String eventId,
    String questionId,
    String teamId, {
    required int selectedOptionIndex,
    String? uid,
  });

  /// 当該問題の全チームの回答を購読する（運営用）。
  Stream<List<QuizAnswer>> watchByQuestion(String eventId, String questionId);
}

final class FirestoreQuizAnswerRepository implements QuizAnswerRepository {
  FirestoreQuizAnswerRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _collection(String eventId) =>
      _firestore.collection('quizEvents').doc(eventId).collection('answers');

  @override
  Stream<QuizAnswer?> watchByQuestionAndTeam(String eventId, String questionId, String teamId) {
    return _collection(eventId).doc('${questionId}_$teamId').snapshots(includeMetadataChanges: true).map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return QuizAnswer.fromJson(<String, dynamic>{...data, 'id': snapshot.id}).copyWith(
        isFromCache: snapshot.metadata.isFromCache,
        hasPendingWrites: snapshot.metadata.hasPendingWrites,
      );
    });
  }

  @override
  Future<void> submit(
    String eventId,
    String questionId,
    String teamId, {
    required int selectedOptionIndex,
    String? uid,
  }) async {
    await _functions
        .httpsCallable(
          'submitQuizAnswer',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
        )
        .call<void>(<String, dynamic>{
          'eventId': eventId,
          'questionId': questionId,
          'teamId': teamId,
          'selectedOptionIndex': selectedOptionIndex,
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
