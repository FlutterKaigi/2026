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
    // status の whereIn では一部環境（エミュレータの gRPC 経路）でルール評価が
    // 失敗するため、公開判定は専用フラグに寄せている。
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
    final data = event.toJson()
      ..remove('id')
      ..remove('createdAt')
      ..remove('updatedAt');
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (event.isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
      final ref = await _collection.add(data);
      return ref.id;
    }
    await _collection.doc(event.id).set(data, SetOptions(merge: true));
    return event.id;
  }
}
