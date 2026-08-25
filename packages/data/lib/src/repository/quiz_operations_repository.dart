import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/quiz_event.dart';
import '../model/quiz_question.dart';

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

abstract interface class QuizOperationsRepository {
  /// イベントを公開する（`draft` → `published`）。
  ///
  /// 参加者アプリのイベント一覧に表示されるのはこの操作以降。
  Future<void> publishEvent(String eventId);

  /// イベントを非公開に戻す（`published` → `draft`）。受付開始前のみ可能。
  Future<void> unpublishEvent(String eventId);

  /// 参加受付を開始する（`published` → `registration`）。
  ///
  /// 参加者アプリに受付画面（受付コード入力つき）が表示されるのはこの操作以降。
  Future<void> openRegistration(String eventId);

  /// 参加受付を終了する（`registration` → `entryClosed`）。
  ///
  /// 以降の新規参加登録はセキュリティルールでも拒否される。
  Future<void> closeRegistration(String eventId);

  /// 参加者をシャッフルしてチーム編成する。受付終了（`entryClosed`）後に実行する。
  Future<void> buildTeams(String eventId);

  /// 現地受付コードを購読する（運営のみ読める）。未生成なら `null` を流す。
  Stream<String?> watchEntryCode(String eventId);

  /// 現地受付コードを新規生成して保存し、生成したコードを返す。
  ///
  /// イベント作成直後の初回生成と、漏洩時の再生成の両方に使う。
  Future<String> regenerateEntryCode(String eventId);

  /// 問題を出題する。`status = open`、`closesAt = now + durationSeconds` を設定し、
  /// 全チーム分の回答ドキュメントを事前作成する。
  Future<void> openQuestion(String eventId, String questionId);

  /// 問題を締め切る（`status = closed`）。
  Future<void> closeQuestion(String eventId, String questionId);

  /// 正解を発表する。採点・スコア再集計・正解コピーを単一バッチで冪等に行う。
  Future<void> revealQuestion(String eventId, String questionId);

  /// 結果を確定する。順位（dense ranking）と各チームのパーフェクト達成スポンサーを
  /// 一括判定し、`event.status = finished` にする。
  Future<void> finalizeEvent(String eventId);
}

final class FirestoreQuizOperationsRepository implements QuizOperationsRepository {
  FirestoreQuizOperationsRepository({FirebaseFirestore? firestore, Random? random})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _random = random ?? Random();

  final FirebaseFirestore _firestore;
  final Random _random;

  DocumentReference<Map<String, dynamic>> _eventRef(String eventId) => _firestore.collection('quizEvents').doc(eventId);

  CollectionReference<Map<String, dynamic>> _participants(String eventId) => _eventRef(eventId).collection('participants');

  CollectionReference<Map<String, dynamic>> _teams(String eventId) => _eventRef(eventId).collection('teams');

  CollectionReference<Map<String, dynamic>> _questions(String eventId) => _eventRef(eventId).collection('questions');

  CollectionReference<Map<String, dynamic>> _answers(String eventId) => _eventRef(eventId).collection('answers');

  DocumentReference<Map<String, dynamic>> _entryCodeRef(String eventId) =>
      _eventRef(eventId).collection('secret').doc('entry');

  /// ステータスを [from] のいずれかから [to] へ進める。それ以外からの遷移は拒否する。
  Future<void> _transition(String eventId, List<QuizEventStatus> from, QuizEventStatus to) async {
    final snapshot = await _eventRef(eventId).get();
    final status = snapshot.data()?['status'] as String?;
    if (!from.map(_statusValue).contains(status)) {
      throw StateError('Cannot transition to ${_statusValue(to)} when event status is $status');
    }
    await _eventRef(eventId).update(<String, dynamic>{
      'status': _statusValue(to),
      // アプリの一覧クエリ（isPublic == true）と常に整合させる。
      'isPublic': to != QuizEventStatus.draft,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> publishEvent(String eventId) =>
      _transition(eventId, const [QuizEventStatus.draft], QuizEventStatus.published);

  @override
  Future<void> unpublishEvent(String eventId) =>
      _transition(eventId, const [QuizEventStatus.published], QuizEventStatus.draft);

  @override
  Future<void> openRegistration(String eventId) =>
      _transition(eventId, const [QuizEventStatus.published], QuizEventStatus.registration);

  @override
  Future<void> closeRegistration(String eventId) =>
      _transition(eventId, const [QuizEventStatus.registration], QuizEventStatus.entryClosed);

  @override
  Stream<String?> watchEntryCode(String eventId) {
    return _entryCodeRef(eventId).snapshots().map((snapshot) => snapshot.data()?['code'] as String?);
  }

  @override
  Future<String> regenerateEntryCode(String eventId) async {
    // 6 桁の数字コード。現地の掲示から手入力しやすい形式にする。
    final code = (_random.nextInt(900000) + 100000).toString();
    await _entryCodeRef(eventId).set(<String, dynamic>{'code': code});
    return code;
  }

  @override
  Future<void> buildTeams(String eventId) async {
    final eventSnapshot = await _eventRef(eventId).get();
    final status = eventSnapshot.data()?['status'] as String?;
    // 受付終了後のみ編成できる（受付中の編成は登録との競合、開始後の再編成は
    // 出題済みの回答ドキュメントと不整合になるため禁止する）。
    if (status != _statusValue(QuizEventStatus.entryClosed)) {
      throw StateError('Cannot build teams when event status is $status');
    }

    // イベントに設定されたチーム名プール（未設定なら既定の Widget 名を使う）。
    final namePool =
        ((eventSnapshot.data()?['teamNamePool'] as List<dynamic>?) ?? const [])
            .whereType<String>()
            .where((name) => name.trim().isNotEmpty)
            .map((name) => name.trim())
            .toList();

    final snapshot = await _participants(eventId).get();
    final participants = snapshot.docs.toList()..shuffle(_random);

    final sizes = splitIntoTeamSizes(participants.length);

    final batch = _firestore.batch();

    // 再実行（編成のやり直し）に備え、既存チームを削除してから作り直す。
    final existingTeams = await _teams(eventId).get();
    for (final doc in existingTeams.docs) {
      batch.delete(doc.reference);
    }

    var index = 0;
    for (var i = 0; i < sizes.length; i++) {
      final tableNumber = i + 1;
      final size = sizes[i];
      final teamRef = _teams(eventId).doc();
      final memberDocs = participants.sublist(index, index + size);
      index += size;

      final memberUids = <String>[];
      final members = <Map<String, dynamic>>[];
      for (final doc in memberDocs) {
        final displayName = (doc.data()['displayName'] as String?) ?? '';
        memberUids.add(doc.id);
        members.add(<String, dynamic>{'uid': doc.id, 'displayName': displayName});
        batch.update(doc.reference, <String, dynamic>{'teamId': teamRef.id});
      }

      batch.set(teamRef, <String, dynamic>{
        'tableNumber': tableNumber,
        'name': _teamName(tableNumber, namePool),
        'memberUids': memberUids,
        'members': members,
        'score': 0,
        'rank': null,
        'perfectSponsorIds': <String>[],
      });
    }

    batch.update(_eventRef(eventId), <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> openQuestion(String eventId, String questionId) async {
    final questionSnapshot = await _questions(eventId).doc(questionId).get();
    final questionData = questionSnapshot.data();
    if (questionData == null) {
      throw StateError('Question not found: $questionId');
    }
    final question = QuizQuestion.fromJson(<String, dynamic>{...questionData, 'id': questionSnapshot.id});
    // 再実行すると回答ドキュメントが初期化され提出済みの回答が消えるため、draft のみ許可する。
    if (question.status != QuizQuestionStatus.draft) {
      throw StateError('Cannot open question in status ${question.status}');
    }

    final teamsSnapshot = await _teams(eventId).get();

    final now = DateTime.now();
    final closesAt = now.add(Duration(seconds: question.durationSeconds));

    final batch = _firestore.batch();

    batch.update(_questions(eventId).doc(questionId), <String, dynamic>{
      'status': _questionStatusValue(QuizQuestionStatus.open),
      'openedAt': FieldValue.serverTimestamp(),
      'closesAt': Timestamp.fromDate(closesAt),
    });

    batch.update(_eventRef(eventId), <String, dynamic>{
      'currentQuestionId': questionId,
      'status': _statusValue(QuizEventStatus.inProgress),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final teamDoc in teamsSnapshot.docs) {
      final answerRef = _answers(eventId).doc('${questionId}_${teamDoc.id}');
      batch.set(answerRef, <String, dynamic>{
        'questionId': questionId,
        'teamId': teamDoc.id,
        'selectedOptionIndex': null,
        'answeredBy': null,
        'submittedAt': null,
        'isCorrect': null,
      });
    }

    await batch.commit();
  }

  @override
  Future<void> closeQuestion(String eventId, String questionId) {
    return _questions(eventId).doc(questionId).update(<String, dynamic>{
      'status': _questionStatusValue(QuizQuestionStatus.closed),
    });
  }

  @override
  Future<void> revealQuestion(String eventId, String questionId) async {
    final questionSnapshot = await _questions(eventId).doc(questionId).get();
    final questionStatus = questionSnapshot.data()?['status'] as String?;
    // 回答受付中に実行すると締切前に正解が公開されてしまうため、締切後のみ許可する。
    // revealed は冪等な再実行（採点のやり直し）のために許可する。
    if (questionStatus != _questionStatusValue(QuizQuestionStatus.closed) &&
        questionStatus != _questionStatusValue(QuizQuestionStatus.revealed)) {
      throw StateError('Cannot reveal question in status $questionStatus');
    }

    final secretSnapshot = await _questions(eventId).doc(questionId).collection('secret').doc('answer').get();
    final secretData = secretSnapshot.data();
    if (secretData == null) {
      throw StateError('Secret answer not found for question: $questionId');
    }
    final correctOptionIndex = (secretData['correctOptionIndex'] as num).toInt();
    // 解説は LocaleMap（{ja, en} のマップ）。中身には触れずそのままコピーする。
    final explanation = secretData['explanation'];

    // 当該問題の回答を採点する。
    final questionAnswers = await _answers(eventId).where('questionId', isEqualTo: questionId).get();
    final gradedIsCorrect = <String, bool>{};
    for (final doc in questionAnswers.docs) {
      final selected = (doc.data()['selectedOptionIndex'] as num?)?.toInt();
      gradedIsCorrect[doc.id] = selected != null && selected == correctOptionIndex;
    }

    // 冪等な再集計: イベント内の全回答を読み、今回採点分はメモリ上の値で上書きして
    // 各チームの score = 正解数 × 10 を毎回計算し直す。
    final allAnswers = await _answers(eventId).get();
    final correctCountByTeam = <String, int>{};
    for (final doc in allAnswers.docs) {
      final data = doc.data();
      final teamId = data['teamId'] as String?;
      if (teamId == null) continue;
      final bool isCorrect;
      if (gradedIsCorrect.containsKey(doc.id)) {
        isCorrect = gradedIsCorrect[doc.id]!;
      } else {
        isCorrect = data['isCorrect'] == true;
      }
      if (isCorrect) {
        correctCountByTeam[teamId] = (correctCountByTeam[teamId] ?? 0) + 1;
      }
    }

    final teamsSnapshot = await _teams(eventId).get();

    final batch = _firestore.batch();

    for (final entry in gradedIsCorrect.entries) {
      batch.update(_answers(eventId).doc(entry.key), <String, dynamic>{'isCorrect': entry.value});
    }

    for (final teamDoc in teamsSnapshot.docs) {
      final score = (correctCountByTeam[teamDoc.id] ?? 0) * 10;
      batch.update(teamDoc.reference, <String, dynamic>{'score': score});
    }

    batch.update(_questions(eventId).doc(questionId), <String, dynamic>{
      'status': _questionStatusValue(QuizQuestionStatus.revealed),
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
    });

    await batch.commit();
  }

  @override
  Future<void> finalizeEvent(String eventId) async {
    final teamsSnapshot = await _teams(eventId).get();
    final questionsSnapshot = await _questions(eventId).get();
    final answersSnapshot = await _answers(eventId).get();

    // questionId -> sponsorId
    final sponsorByQuestion = <String, String>{};
    // sponsorId -> その社の全問題 ID
    final questionsBySponsor = <String, Set<String>>{};
    for (final doc in questionsSnapshot.docs) {
      final sponsorId = doc.data()['sponsorId'] as String?;
      if (sponsorId == null) continue;
      sponsorByQuestion[doc.id] = sponsorId;
      (questionsBySponsor[sponsorId] ??= <String>{}).add(doc.id);
    }

    // teamId -> (sponsorId -> 正解した問題 ID の集合)
    final correctQuestionsByTeamSponsor = <String, Map<String, Set<String>>>{};
    for (final doc in answersSnapshot.docs) {
      final data = doc.data();
      if (data['isCorrect'] != true) continue;
      final teamId = data['teamId'] as String?;
      final questionId = data['questionId'] as String?;
      if (teamId == null || questionId == null) continue;
      final sponsorId = sponsorByQuestion[questionId];
      if (sponsorId == null) continue;
      final bySponsor = correctQuestionsByTeamSponsor[teamId] ??= <String, Set<String>>{};
      (bySponsor[sponsorId] ??= <String>{}).add(questionId);
    }

    // dense ranking: score 降順、同点は同順位。
    final scoreByTeam = <String, int>{
      for (final doc in teamsSnapshot.docs) doc.id: (doc.data()['score'] as num?)?.toInt() ?? 0,
    };
    final distinctScoresDesc = scoreByTeam.values.toSet().toList()..sort((a, b) => b.compareTo(a));
    final rankByScore = <int, int>{
      for (var i = 0; i < distinctScoresDesc.length; i++) distinctScoresDesc[i]: i + 1,
    };

    final batch = _firestore.batch();

    for (final teamDoc in teamsSnapshot.docs) {
      final teamId = teamDoc.id;
      final score = scoreByTeam[teamId] ?? 0;
      final rank = rankByScore[score];

      // パーフェクト判定: スポンサーの全問題を正解していれば達成。
      final perfectSponsorIds = <String>[];
      final correctBySponsor = correctQuestionsByTeamSponsor[teamId] ?? const <String, Set<String>>{};
      for (final entry in questionsBySponsor.entries) {
        final sponsorId = entry.key;
        final sponsorQuestions = entry.value;
        if (sponsorQuestions.isEmpty) continue;
        final correctForSponsor = correctBySponsor[sponsorId] ?? const <String>{};
        if (correctForSponsor.containsAll(sponsorQuestions)) {
          perfectSponsorIds.add(sponsorId);
        }
      }

      batch.update(teamDoc.reference, <String, dynamic>{
        'rank': rank,
        'perfectSponsorIds': perfectSponsorIds,
      });
    }

    batch.update(_eventRef(eventId), <String, dynamic>{
      'status': _statusValue(QuizEventStatus.finished),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// テーブル番号からチーム名を決める。イベント設定のプールを優先し、
  /// 未設定・不足分は既定の Widget 名、それも尽きたら `Team N`。
  String _teamName(int tableNumber, List<String> namePool) {
    final index = tableNumber - 1;
    if (index >= 0 && index < namePool.length) {
      return namePool[index];
    }
    if (index >= 0 && index < quizTeamWidgetNames.length) {
      return quizTeamWidgetNames[index];
    }
    return 'Team $tableNumber';
  }

  String _statusValue(QuizEventStatus status) => switch (status) {
    QuizEventStatus.draft => 'draft',
    QuizEventStatus.published => 'published',
    QuizEventStatus.registration => 'registration',
    QuizEventStatus.entryClosed => 'entryClosed',
    QuizEventStatus.inProgress => 'inProgress',
    QuizEventStatus.finished => 'finished',
  };

  String _questionStatusValue(QuizQuestionStatus status) => switch (status) {
    QuizQuestionStatus.draft => 'draft',
    QuizQuestionStatus.open => 'open',
    QuizQuestionStatus.closed => 'closed',
    QuizQuestionStatus.revealed => 'revealed',
  };
}
