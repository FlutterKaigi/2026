import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 対象イベントの ID。
///
/// イベント一覧から遷移した `QuizPage` が `ProviderScope` の override で
/// 供給する。override なしで読むのは実装ミスなので例外にする。
final quizEventIdProvider = Provider<String>(
  (ref) => throw UnimplementedError('quizEventIdProvider は QuizPage のスコープで override される'),
  dependencies: const [],
);

/// クイズイベントの一覧（作成の新しい順）。イベント一覧ページで使う。
///
/// 非公開（draft）のイベントはセキュリティルールで読めないため、
/// draft を除外した公開クエリで購読する。
final quizEventsProvider = StreamProvider<List<QuizEvent>>(
  (ref) => ref.watch(quizEventRepositoryProvider).watchPublished(),
);

/// 匿名サインインを行い、確定した `uid` を返す。
///
/// 画面表示時に評価され、未サインインなら `signInAnonymously()` を呼ぶ。
/// 認証状態のストリームを購読し、最初に得られた非 null のユーザーの `uid` を
/// 返す。サインイン済みならそのまま既存の `uid` を返す。
final quizSignInProvider = FutureProvider<String>((ref) async {
  final auth = ref.watch(quizAuthRepositoryProvider);
  final current = await auth.authStateChanges().first;
  if (current != null) {
    return current.uid;
  }
  await auth.signInAnonymously();
  final user = await auth.authStateChanges().firstWhere((user) => user != null);
  return user!.uid;
});

/// 対象イベントを購読する。
///
/// サインイン完了後に評価されるよう [quizSignInProvider] に依存する。
/// 匿名認証前に Firestore を読むと read が拒否されるのを避ける。
final quizEventProvider = StreamProvider<QuizEvent?>((ref) {
  final uid = ref.watch(quizSignInProvider).value;
  if (uid == null) {
    return const Stream<QuizEvent?>.empty();
  }
  final eventId = ref.watch(quizEventIdProvider);
  return ref.watch(quizEventRepositoryProvider).watchById(eventId);
}, dependencies: [quizEventIdProvider]);

/// 自分の参加者ドキュメントを購読する。未登録の間は `null` を流す。
final myParticipantProvider = StreamProvider<QuizParticipant?>((ref) {
  final uid = ref.watch(quizSignInProvider).value;
  if (uid == null) {
    return const Stream<QuizParticipant?>.empty();
  }
  final eventId = ref.watch(quizEventIdProvider);
  return ref.watch(quizParticipantRepositoryProvider).watchByUid(eventId, uid);
}, dependencies: [quizEventIdProvider]);

/// 参加者の一覧を購読する。参加人数の表示に使う。
final quizParticipantsProvider = StreamProvider<List<QuizParticipant>>((ref) {
  final uid = ref.watch(quizSignInProvider).value;
  if (uid == null) {
    return const Stream<List<QuizParticipant>>.empty();
  }
  final eventId = ref.watch(quizEventIdProvider);
  return ref.watch(quizParticipantRepositoryProvider).watchAll(eventId);
}, dependencies: [quizEventIdProvider]);

/// 全チームを購読する。最終結果のランキング表示に使う。
final quizTeamsProvider = StreamProvider<List<QuizTeam>>((ref) {
  final uid = ref.watch(quizSignInProvider).value;
  if (uid == null) {
    return const Stream<List<QuizTeam>>.empty();
  }
  final eventId = ref.watch(quizEventIdProvider);
  return ref.watch(quizTeamRepositoryProvider).watchAll(eventId);
}, dependencies: [quizEventIdProvider]);

/// 自分が所属するチームを購読する。
///
/// 参加者の `teamId` が確定するまでは `null` を流す。
///
/// `select` で `teamId` の変化だけに反応させ、参加者ドキュメントの他の
/// フィールド更新のたびに Firestore リスナーが張り直されるのを防ぐ。
final myTeamProvider = StreamProvider<QuizTeam?>((ref) {
  final teamId = ref.watch(
    myParticipantProvider.select((participant) => participant.value?.teamId),
  );
  if (teamId == null) {
    return Stream.value(null);
  }
  final eventId = ref.watch(quizEventIdProvider);
  return ref.watch(quizTeamRepositoryProvider).watchById(eventId, teamId);
}, dependencies: [myParticipantProvider, quizEventIdProvider]);

/// 現在出題中の問題を購読する。
///
/// イベントの `currentQuestionId` が未設定の間は `null` を流す。
///
/// イベントドキュメントは status 変更などでも更新されるため、`select` で
/// `currentQuestionId` の変化だけに反応させて購読の張り直しを防ぐ。
final currentQuestionProvider = StreamProvider<QuizQuestion?>((ref) {
  final questionId = ref.watch(
    quizEventProvider.select((event) => event.value?.currentQuestionId),
  );
  if (questionId == null) {
    return Stream.value(null);
  }
  final eventId = ref.watch(quizEventIdProvider);
  return ref.watch(quizQuestionRepositoryProvider).watchById(eventId, questionId);
}, dependencies: [quizEventProvider, quizEventIdProvider]);

/// 現在の問題に対する自チームの回答を購読する。
///
/// 現在の問題または自チームが未確定の間、および出題前で回答ドキュメントが
/// 未作成の間は `null` を流す。
///
/// 問題ドキュメントは status や closesAt の更新でも変化するため、`select`
/// で id の変化だけに反応させて購読の張り直しを防ぐ。
final teamAnswerProvider = StreamProvider<QuizAnswer?>((ref) {
  final questionId = ref.watch(
    currentQuestionProvider.select((question) => question.value?.id),
  );
  final teamId = ref.watch(myTeamProvider.select((team) => team.value?.id));
  if (questionId == null || teamId == null) {
    return Stream.value(null);
  }
  final eventId = ref.watch(quizEventIdProvider);
  return ref.watch(quizAnswerRepositoryProvider).watchByQuestionAndTeam(eventId, questionId, teamId);
}, dependencies: [currentQuestionProvider, myTeamProvider, quizEventIdProvider]);

/// 全スポンサーを購読する。出題画面でスポンサー名を引くのに使う。
final quizSponsorsProvider = StreamProvider<List<Sponsor>>((ref) {
  return ref.watch(quizSponsorRepositoryProvider).watchAll();
});
