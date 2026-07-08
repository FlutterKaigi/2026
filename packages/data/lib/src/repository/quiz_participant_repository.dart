import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/quiz_participant.dart';

abstract interface class QuizParticipantRepository {
  /// 参加者を登録する。ドキュメント ID は [uid]。`registeredAt` は
  /// サーバ時刻で書き込む。Firestore ルール上 `status == 'registration'` の
  /// 間のみ本人が create できる。
  Future<void> register(String eventId, String uid, String displayName);
  Stream<List<QuizParticipant>> watchAll(String eventId);

  /// 指定 uid の参加者を購読する。未登録の間は `null` を流す。
  Stream<QuizParticipant?> watchByUid(String eventId, String uid);
}

final class FirestoreQuizParticipantRepository implements QuizParticipantRepository {
  FirestoreQuizParticipantRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String eventId) =>
      _firestore.collection('quizEvents').doc(eventId).collection('participants');

  @override
  Future<void> register(String eventId, String uid, String displayName) {
    return _collection(eventId).doc(uid).set(<String, dynamic>{
      'displayName': displayName,
      'registeredAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<QuizParticipant>> watchAll(String eventId) {
    return _collection(eventId)
        .orderBy('registeredAt')
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) QuizParticipant.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }

  @override
  Stream<QuizParticipant?> watchByUid(String eventId, String uid) {
    return _collection(eventId).doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return QuizParticipant.fromJson(<String, dynamic>{...data, 'id': snapshot.id});
    });
  }
}
