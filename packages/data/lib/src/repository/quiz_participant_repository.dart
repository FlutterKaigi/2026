import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/quiz_participant.dart';

abstract interface class QuizParticipantRepository {
  /// 参加者を登録する。ドキュメント ID は [uid]。`registeredAt` は
  /// サーバ時刻で書き込む。
  ///
  /// [entryCode] は現地受付に掲示されるコード。参加者ドキュメントとは別の
  /// 読み取り不可コレクション（`entryClaims/{uid}`）へ先に書き込み、
  /// その時点でセキュリティルールが `secret/entry` のコードと突き合わせて
  /// 検証する。コード不一致・受付時間外は `permission-denied` で失敗する。
  Future<void> register(String eventId, String uid, String displayName, String entryCode);
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
  Future<void> register(String eventId, String uid, String displayName, String entryCode) async {
    // コードは参加者ドキュメント（公開読み取り）には載せず、読み取り不可の
    // entryClaims にのみ書く。コードの照合はこの書き込みのルールで行われる
    // ため、不一致ならここで permission-denied になり参加者は作成されない。
    await _firestore.collection('quizEvents').doc(eventId).collection('entryClaims').doc(uid).set(<String, dynamic>{
      'code': entryCode,
    });
    await _collection(eventId).doc(uid).set(<String, dynamic>{
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
