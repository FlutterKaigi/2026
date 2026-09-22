import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/quiz_event.dart';

abstract interface class QuizEventRepository {
  /// 全イベントを購読する（運営ダッシュボード用。非公開の draft も含む）。
  Stream<List<QuizEvent>> watchAll();

  /// 公開中のイベントのみ購読する（参加者アプリ用）。
  ///
  /// `draft` を除外したクエリを投げる。セキュリティルール側も draft の
  /// list を非管理者に許可しないため、クエリ条件はルールと一致させること。
  Stream<List<QuizEvent>> watchPublished();

  Stream<QuizEvent?> watchById(String eventId);

  /// イベントを保存し、ドキュメント ID を返す（新規作成時は採番された ID）。
  Future<String> save(QuizEvent event);

  Future<void> updateTeamNamePool(String eventId, List<String> names);
}

final class FirestoreQuizEventRepository implements QuizEventRepository {
  FirestoreQuizEventRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('quizEvents');

  @override
  Stream<List<QuizEvent>> watchAll() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) QuizEvent.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }

  @override
  Stream<List<QuizEvent>> watchPublished() {
    // ルールの list 条件（isPublic == true）をクエリの等価条件で保証する。
    return _collection
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) QuizEvent.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }

  @override
  Stream<QuizEvent?> watchById(String eventId) {
    return _collection.doc(eventId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return QuizEvent.fromJson(<String, dynamic>{...data, 'id': snapshot.id});
    });
  }

  @override
  Future<String> save(QuizEvent event) async {
    if (event.capacity < 3 || event.capacity > 80) {
      throw ArgumentError('定員は 3〜80 人で設定してください。');
    }
    // 編集画面が保持する古い status/currentQuestionId で進行を巻き戻さない。
    final data = <String, dynamic>{
      'title': event.title.toJson(),
      'sponsorIds': event.sponsorIds,
      'capacity': event.capacity,
      'teamNamePool': event.teamNamePool,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (event.isNew) {
      data.addAll({
        'status': 'draft',
        'isPublic': false,
        'currentQuestionId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return (await _collection.add(data)).id;
    }
    await _firestore.runTransaction((transaction) async {
      final reference = _collection.doc(event.id);
      final current = await transaction.get(reference);
      if (current.data() == null ||
          !const ['draft', 'published', 'registration', 'entryClosed'].contains(current.data()?['status'])) {
        throw StateError('クイズ開始後はイベント設定を変更できません。');
      }
      if (event.capacity != (current.data()?['capacity'] ?? 80) &&
          (!const ['draft', 'published'].contains(current.data()?['status']) ||
              current.data()?['admissionSlotsReady'] == true)) {
        throw StateError('受付開始後は定員を変更できません。');
      }
      if (event.capacity < ((current.data()?['participantCount'] as num?)?.toInt() ?? 0)) {
        throw StateError('登録済みの参加者数より定員を減らせません。');
      }
      transaction.update(reference, data);
    });
    return event.id;
  }

  @override
  Future<void> updateTeamNamePool(String eventId, List<String> names) => _collection.doc(eventId).update({
    'teamNamePool': names,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
