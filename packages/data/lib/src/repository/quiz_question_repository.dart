import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/quiz_question.dart';
import '../model/quiz_question_secret.dart';
import 'firestore_watch.dart';

abstract interface class QuizQuestionRepository {
  /// 問題を `order` 昇順で購読する。draft の問題は Firestore ルール上
  /// 参加者から list できないため、参加者は主に [watchById] を使う。
  Stream<List<QuizQuestion>> watchAll(String eventId);
  Stream<QuizQuestion?> watchById(String eventId, String questionId);

  /// 運営用。正解・解説を公開用問題とは分けて読み込む。
  Stream<QuizQuestionSecret?> watchSecret(String eventId, String questionId);

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
  Stream<QuizQuestionSecret?> watchSecret(String eventId, String questionId) =>
      waitForUsableInitialSnapshot(
        _secretRef(eventId, questionId).snapshots(includeMetadataChanges: true),
        isUsableInitialSnapshot: (snapshot) => !snapshot.metadata.isFromCache,
      ).map((snapshot) {
        final data = snapshot.data();
        return data == null ? null : QuizQuestionSecret.fromJson(data);
      });

  @override
  Future<void> save(String eventId, QuizQuestion question, QuizQuestionSecret secret) async {
    if (question.durationSeconds < 1 || question.durationSeconds > 1800) {
      throw ArgumentError('制限時間は 1〜1800 秒で設定してください。');
    }
    if (question.options.length < 2 || question.options.length > 4) {
      throw ArgumentError('選択肢は 2〜4 件で設定してください。');
    }
    final eventRef = _firestore.collection('quizEvents').doc(eventId);
    final questionRef = question.isNew ? _collection(eventId).doc() : _collection(eventId).doc(question.id);
    await _firestore.runTransaction((transaction) async {
      final event = await transaction.get(eventRef);
      final current = await transaction.get(questionRef);
      _requireEditableEvent(event.data());
      if (!question.isNew && (current.data() == null || current.data()?['status'] != 'draft')) {
        throw StateError('この問題は既に出題されたため保存できません。');
      }
      if (secret.correctOptionIndex < 0 || secret.correctOptionIndex >= question.options.length) {
        throw ArgumentError('正解の選択肢がありません。');
      }
      final content = <String, dynamic>{
        'sponsorId': question.sponsorId,
        'order': question.order,
        'title': question.title.toJson(),
        'options': question.options.map((option) => option.toJson()).toList(),
        'durationSeconds': question.durationSeconds,
      };
      if (question.isNew) {
        transaction.set(questionRef, {...content, 'status': 'draft'});
      } else {
        transaction.update(questionRef, content);
      }
      transaction.set(_secretRef(eventId, questionRef.id), secret.toJson());
    });
  }

  @override
  Future<void> delete(String eventId, String questionId) async {
    final eventRef = _firestore.collection('quizEvents').doc(eventId);
    final questionRef = _collection(eventId).doc(questionId);
    await _firestore.runTransaction((transaction) async {
      final event = await transaction.get(eventRef);
      final current = await transaction.get(questionRef);
      _requireEditableEvent(event.data());
      if (current.data() == null || current.data()?['status'] != 'draft') {
        throw StateError('出題済みの問題は削除できません。');
      }
      transaction.delete(_secretRef(eventId, questionId));
      transaction.delete(questionRef);
    });
  }

  void _requireEditableEvent(Map<String, dynamic>? event) {
    if (event == null || !const ['draft', 'published', 'registration', 'entryClosed'].contains(event['status'])) {
      throw StateError('クイズ開始後は問題を編集できません。');
    }
  }
}
