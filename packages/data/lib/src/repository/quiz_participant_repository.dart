import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../model/quiz_participant.dart';
import '../model/quiz_participant_account.dart';

abstract interface class QuizParticipantRepository {
  /// 認証アカウントの公開プロフィールで参加表明する。
  Future<void> register(String eventId);

  /// 会場で配られた6桁の参加コードでチェックインする。
  Future<void> checkIn(String eventId, String code);

  /// チェックイン後にチームを選ぶ。
  Future<void> selectTeam(String eventId, String teamId, {required String? expectedTeamId});

  Stream<List<QuizParticipant>> watchAll(String eventId);

  /// 指定 uid の参加者を購読する。未登録の間は `null` を流す。
  Stream<QuizParticipant?> watchByUid(String eventId, String uid);

  /// 指定 uid のアカウント紐づけを取得する。未登録の間は `null` を返す。
  ///
  /// 読めるのは本人と運営のみ。
  Future<QuizParticipantAccount?> findAccount(String eventId, String uid);
}

final class FirestoreQuizParticipantRepository implements QuizParticipantRepository {
  FirestoreQuizParticipantRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  DocumentReference<Map<String, dynamic>> _event(String eventId) => _firestore.collection('quizEvents').doc(eventId);

  CollectionReference<Map<String, dynamic>> _collection(String eventId) => _event(eventId).collection('participants');

  CollectionReference<Map<String, dynamic>> _accounts(String eventId) =>
      _event(eventId).collection('participantAccounts');

  @override
  Future<void> register(String eventId) async {
    await _functions
        .httpsCallable(
          'registerQuizParticipant',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
        )
        .call<void>({'eventId': eventId});
  }

  @override
  Future<void> checkIn(String eventId, String code) async {
    await _functions.httpsCallable('checkInQuizParticipant').call<void>({'eventId': eventId, 'code': code});
  }

  @override
  Future<void> selectTeam(String eventId, String teamId, {required String? expectedTeamId}) async {
    await _functions.httpsCallable('selectQuizTeam').call<void>({
      'eventId': eventId,
      'teamId': teamId,
      'expectedTeamId': expectedTeamId,
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

  @override
  Future<QuizParticipantAccount?> findAccount(String eventId, String uid) async {
    final snapshot = await _accounts(eventId).doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    return QuizParticipantAccount.fromJson(<String, dynamic>{...data, 'uid': snapshot.id});
  }
}
