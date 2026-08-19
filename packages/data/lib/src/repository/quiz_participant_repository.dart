import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/quiz_participant.dart';
import '../model/quiz_participant_account.dart';

abstract interface class QuizParticipantRepository {
  /// 参加者を登録する。ドキュメント ID は [uid]。`registeredAt` は
  /// サーバ時刻で書き込む。
  ///
  /// クイズ大会はログイン必須のため、[uid] は匿名ではない実アカウントのもの
  /// である必要がある（セキュリティルールが `sign_in_provider` で検証する）。
  /// [signInProvider] 以下のアカウント情報は読み取りを本人と運営に限定した
  /// `participantAccounts/{uid}` に保存し、参加記録をログインアカウントに
  /// 紐づける。
  ///
  /// [entryCode] は現地受付に掲示されるコード。参加者ドキュメントとは別の
  /// 読み取り不可コレクション（`entryClaims/{uid}`）へ先に書き込み、
  /// その時点でセキュリティルールが `secret/entry` のコードと突き合わせて
  /// 検証する。コード不一致・受付時間外は `permission-denied` で失敗する。
  Future<void> register(
    String eventId, {
    required String uid,
    required String displayName,
    required String entryCode,
    required String signInProvider,
    String? email,
    String? accountName,
    String? photoUrl,
  });

  Stream<List<QuizParticipant>> watchAll(String eventId);

  /// 指定 uid の参加者を購読する。未登録の間は `null` を流す。
  Stream<QuizParticipant?> watchByUid(String eventId, String uid);

  /// 指定 uid のアカウント紐づけを取得する。未登録の間は `null` を返す。
  ///
  /// 読めるのは本人と運営のみ。
  Future<QuizParticipantAccount?> findAccount(String eventId, String uid);
}

final class FirestoreQuizParticipantRepository implements QuizParticipantRepository {
  FirestoreQuizParticipantRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _event(String eventId) => _firestore.collection('quizEvents').doc(eventId);

  CollectionReference<Map<String, dynamic>> _collection(String eventId) => _event(eventId).collection('participants');

  CollectionReference<Map<String, dynamic>> _accounts(String eventId) =>
      _event(eventId).collection('participantAccounts');

  @override
  Future<void> register(
    String eventId, {
    required String uid,
    required String displayName,
    required String entryCode,
    required String signInProvider,
    String? email,
    String? accountName,
    String? photoUrl,
  }) async {
    // コードは参加者ドキュメント（サインイン済みなら読める）には載せず、
    // 読み取り不可の entryClaims にのみ書く。コードの照合はこの書き込みの
    // ルールで行われるため、不一致ならここで permission-denied になり
    // 参加者は作成されない。
    await _event(eventId).collection('entryClaims').doc(uid).set(<String, dynamic>{'code': entryCode});

    // ログインアカウントとの紐づけ。参加者ドキュメントの作成ルールが
    // このドキュメントの存在を要求するため、必ず先に書き込む。
    // 値の正しさ（uid / email / signInProvider）はルールが ID トークンと
    // 突き合わせて検証する。
    await _accounts(eventId).doc(uid).set(<String, dynamic>{
      'uid': uid,
      'email': email,
      'accountName': accountName,
      'photoUrl': photoUrl,
      'signInProvider': signInProvider,
      'linkedAt': FieldValue.serverTimestamp(),
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

  @override
  Future<QuizParticipantAccount?> findAccount(String eventId, String uid) async {
    final snapshot = await _accounts(eventId).doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    return QuizParticipantAccount.fromJson(<String, dynamic>{...data, 'uid': snapshot.id});
  }
}
