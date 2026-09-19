import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'firestore_watch.dart';

/// チーム名に使う Flutter Widget 名（演出用）。`tableNumber` 順に割り当てる。
const quizTeamWidgetNames = <String>[
  'Scaffold',
  'Hero',
  'Column',
  'Row',
  'Stack',
  'Center',
  'Padding',
  'Align',
  'Expanded',
  'Flexible',
  'Container',
  'SizedBox',
  'ListView',
  'GridView',
  'AppBar',
  'Drawer',
  'Card',
  'Chip',
  'Badge',
  'Banner',
];

/// 参加者数 [n] を各チームの人数リストへ分割する純粋関数。
///
/// 4 人 1 チームを基本とし、端数は 3〜5 人チームで吸収する:
/// - `n % 4 == 0`: すべて 4 人
/// - `n % 4 == 1` (n >= 5): 4 人チームを 1 つ減らして 5 人チーム 1 つ
/// - `n % 4 == 2` (n >= 6): 4 人チームを 1 つ減らして 3 人 + 3 人
/// - `n % 4 == 3`: 3 人チームを 1 つ追加
///
/// 分割ルールを適用できない小規模（`n <= 5`）は 1 チームにまとめる。
/// `n == 0` の場合は空リストを返す。
///
/// 返すリストの合計は常に [n] に一致する。
List<int> splitIntoTeamSizes(int n) {
  if (n <= 0) return const [];
  if (n <= 5) return [n];

  final base = n ~/ 4;
  final remainder = n % 4;

  switch (remainder) {
    case 0:
      return List<int>.filled(base, 4);
    case 1:
      // 4 人チームを 1 つ減らして 5 人チーム 1 つ。
      return [...List<int>.filled(base - 1, 4), 5];
    case 2:
      // 4 人チームを 1 つ減らして 3 人 + 3 人。
      return [...List<int>.filled(base - 1, 4), 3, 3];
    default: // remainder == 3
      // 3 人チームを 1 つ追加。
      return [...List<int>.filled(base, 4), 3];
  }
}

/// 運営操作はサーバーで認可・状態検証し、トランザクションで実行する。
abstract interface class QuizOperationsRepository {
  Future<void> publishEvent(String eventId);
  Future<void> unpublishEvent(String eventId);
  Future<void> openRegistration(String eventId);
  Future<void> closeRegistration(String eventId);
  Future<void> reopenRegistration(String eventId);
  Future<void> buildTeams(String eventId);
  Future<void> rebuildTeams(String eventId);
  Future<void> removeParticipant(String eventId, String uid);
  Stream<String?> watchEntryCode(String eventId);
  Future<String> regenerateEntryCode(String eventId);

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
  Future<void> buildTeams(String eventId) async => _operate(eventId, 'buildTeams');
  @override
  Future<void> rebuildTeams(String eventId) async => _operate(eventId, 'rebuildTeams');
  @override
  Future<void> removeParticipant(String eventId, String uid) async => _operate(eventId, 'removeParticipant', uid: uid);

  @override
  Stream<String?> watchEntryCode(String eventId) => waitForUsableInitialSnapshot(
    _firestore
        .collection('quizEvents')
        .doc(eventId)
        .collection('secret')
        .doc('entry')
        .snapshots(includeMetadataChanges: true),
    isUsableInitialSnapshot: (snapshot) => !snapshot.metadata.isFromCache,
  ).map((snapshot) => snapshot.data()?['code'] as String?);

  @override
  Future<String> regenerateEntryCode(String eventId) async {
    final result = await _operate(eventId, 'regenerateEntryCode');
    return result['code'] as String;
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
