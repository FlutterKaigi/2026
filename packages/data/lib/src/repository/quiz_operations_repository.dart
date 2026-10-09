import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// 運営操作はサーバーで認可・状態検証し、トランザクションで実行する。
abstract interface class QuizOperationsRepository {
  Future<void> publishEvent(String eventId);
  Future<void> unpublishEvent(String eventId);
  Future<void> openRegistration(String eventId);
  Future<void> closeRegistration(String eventId);
  Future<void> reopenRegistration(String eventId);
  Future<void> openTeamSelection(String eventId);
  Future<void> closeTeamSelection(String eventId);
  Future<int> removeUnselectedParticipants(String eventId);
  Future<void> removeParticipant(String eventId, String uid);

  /// 問題を表示する。読み上げ中は回答を受け付けず、時間も減らない。
  Future<void> presentQuestion(String eventId, String questionId);

  /// 読み上げ後、サーバー時刻を基準に回答受付を開始する。
  Future<void> openQuestion(String eventId, String questionId);
  Future<void> closeQuestion(String eventId, String questionId);
  Future<void> extendQuestion(String eventId, String questionId, {required int seconds});
  Future<void> revealQuestion(String eventId, String questionId);
  Future<void> finalizeEvent(String eventId);
}

final class FirestoreQuizOperationsRepository implements QuizOperationsRepository {
  FirestoreQuizOperationsRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  // 応答が不明な操作は同じ ID で再試行する。他の運営が進行を変更した後でも、
  // 古い操作の再送でその変更を取り消さず、保存済みの実行結果を受け取る。
  final Map<String, String> _pendingOperationIds = {};

  Future<Map<String, dynamic>> _operate(
    String eventId,
    String operation, {
    String? questionId,
    String? uid,
    int? seconds,
  }) async {
    final key = '$eventId/$operation/$questionId/$uid/$seconds';
    if (operation == 'removeUnselectedParticipants') _pendingOperationIds.remove(key);
    final operationId = _pendingOperationIds.putIfAbsent(key, () => _firestore.collection('quizEvents').doc().id);
    try {
      final response = await _functions.httpsCallable('quizEventOperation').call<Map<String, dynamic>>({
        'eventId': eventId,
        'operation': operation,
        'questionId': ?questionId,
        'uid': ?uid,
        'seconds': ?seconds,
        'operationId': operationId,
      });
      _pendingOperationIds.remove(key);
      return response.data;
    } on FirebaseFunctionsException catch (error) {
      // サーバーで拒否された場合は新しい操作としてやり直せる。
      if (const [
        'invalid-argument',
        'failed-precondition',
        'permission-denied',
        'unauthenticated',
        'not-found',
        'resource-exhausted',
      ].contains(error.code)) {
        _pendingOperationIds.remove(key);
      }
      rethrow;
    }
  }

  @override
  Future<void> publishEvent(String eventId) async => _operate(eventId, 'publish');
  @override
  Future<void> unpublishEvent(String eventId) async => _operate(eventId, 'unpublish');
  @override
  Future<void> openRegistration(String eventId) async => _operate(eventId, 'openRegistration');
  @override
  Future<void> closeRegistration(String eventId) async => _operate(eventId, 'closeRegistration');
  @override
  Future<void> reopenRegistration(String eventId) async => _operate(eventId, 'reopenRegistration');
  @override
  Future<void> openTeamSelection(String eventId) async => _operate(eventId, 'openTeamSelection');
  @override
  Future<void> closeTeamSelection(String eventId) async => _operate(eventId, 'closeTeamSelection');
  @override
  Future<void> removeParticipant(String eventId, String uid) async => _operate(eventId, 'removeParticipant', uid: uid);

  @override
  Future<int> removeUnselectedParticipants(String eventId) async {
    final result = await _operate(eventId, 'removeUnselectedParticipants');
    return (result['removedCount'] as num).toInt();
  }

  @override
  Future<void> presentQuestion(String eventId, String questionId) async =>
      _operate(eventId, 'presentQuestion', questionId: questionId);
  @override
  Future<void> openQuestion(String eventId, String questionId) async =>
      _operate(eventId, 'openQuestion', questionId: questionId);
  @override
  Future<void> closeQuestion(String eventId, String questionId) async =>
      _operate(eventId, 'closeQuestion', questionId: questionId);
  @override
  Future<void> extendQuestion(String eventId, String questionId, {required int seconds}) async =>
      _operate(eventId, 'extendQuestion', questionId: questionId, seconds: seconds);
  @override
  Future<void> revealQuestion(String eventId, String questionId) async =>
      _operate(eventId, 'revealQuestion', questionId: questionId);
  @override
  Future<void> finalizeEvent(String eventId) async => _operate(eventId, 'finalizeEvent');
}
