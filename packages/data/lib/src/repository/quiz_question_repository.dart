import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/quiz_question.dart';
import '../model/quiz_question_secret.dart';

abstract interface class QuizQuestionRepository {
  /// 問題を `order` 昇順で購読する。draft の問題は Firestore ルール上
  /// 参加者から list できないため、参加者は主に [watchById] を使う。
  Stream<List<QuizQuestion>> watchAll(String eventId);
  Stream<QuizQuestion?> watchById(String eventId, String questionId);

  /// 問題本体と `secret/answer` を同一バッチで保存する（draft 時のみの想定）。
  Future<void> save(String eventId, QuizQuestion question, QuizQuestionSecret secret);
  Future<void> delete(String eventId, String questionId);
}

final class FirestoreQuizQuestionRepository implements QuizQuestionRepository {
  FirestoreQuizQuestionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String eventId) =>
      _firestore.collection('quizEvents').doc(eventId).collection('questions');

  DocumentReference<Map<String, dynamic>> _secretRef(String eventId, String questionId) =>
      _collection(eventId).doc(questionId).collection('secret').doc('answer');

  @override
  Stream<List<QuizQuestion>> watchAll(String eventId) {
    return _collection(eventId)
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) QuizQuestion.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }

  @override
  Stream<QuizQuestion?> watchById(String eventId, String questionId) {
    return _collection(eventId).doc(questionId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return QuizQuestion.fromJson(<String, dynamic>{...data, 'id': snapshot.id});
    });
  }

  @override
  Future<void> save(String eventId, QuizQuestion question, QuizQuestionSecret secret) async {
    final batch = _firestore.batch();

    // draft の問題のみ保存する前提。open 以降の問題に対して呼ぶと
    // 進行中の実行時フィールド（openedAt / closesAt / correctOptionIndex）を巻き戻してしまう。
    final data = question.toJson()..remove('id');
    if (question.isNew) {
      final ref = _collection(eventId).doc();
      batch.set(ref, data);
      batch.set(_secretRef(eventId, ref.id), secret.toJson());
    } else {
      final ref = _collection(eventId).doc(question.id);
      batch.set(ref, data, SetOptions(merge: true));
      batch.set(_secretRef(eventId, question.id), secret.toJson());
    }

    await batch.commit();
  }

  @override
  Future<void> delete(String eventId, String questionId) async {
    final batch = _firestore.batch();
    batch.delete(_secretRef(eventId, questionId));
    batch.delete(_collection(eventId).doc(questionId));
    await batch.commit();
  }
}
