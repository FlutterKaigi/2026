import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 対象イベントの ID。
///
/// PoC ではシード済みの前半戦イベント `half-1` に固定する。将来はホームの
/// バナー等から選択させる想定で、`overrideWithValue` により差し替え可能にする。
final quizEventIdProvider = Provider<String>((ref) => 'half-1');

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
});

/// 自分の参加者ドキュメントを購読する。未登録の間は `null` を流す。
final myParticipantProvider = StreamProvider<QuizParticipant?>((ref) {
  final uid = ref.watch(quizSignInProvider).value;
  if (uid == null) {
    return const Stream<QuizParticipant?>.empty();
  }
  final eventId = ref.watch(quizEventIdProvider);
  return ref.watch(quizParticipantRepositoryProvider).watchByUid(eventId, uid);
});

/// 参加者の一覧を購読する。参加人数の表示に使う。
final quizParticipantsProvider = StreamProvider<List<QuizParticipant>>((ref) {
  final uid = ref.watch(quizSignInProvider).value;
  if (uid == null) {
    return const Stream<List<QuizParticipant>>.empty();
  }
  final eventId = ref.watch(quizEventIdProvider);
  return ref.watch(quizParticipantRepositoryProvider).watchAll(eventId);
});

/// 全チームを購読する。最終結果のランキング表示に使う。
final quizTeamsProvider = StreamProvider<List<QuizTeam>>((ref) {
  final uid = ref.watch(quizSignInProvider).value;
  if (uid == null) {
    return const Stream<List<QuizTeam>>.empty();
  }
  final eventId = ref.watch(quizEventIdProvider);
  return ref.watch(quizTeamRepositoryProvider).watchAll(eventId);
});

/// 自分が所属するチームを購読する。
///
/// 参加者の `teamId` が確定するまでは `null` を流す。
final myTeamProvider = StreamProvider<QuizTeam?>((ref) {
  final teamId = ref.watch(myParticipantProvider).value?.teamId;
  if (teamId == null) {
    return Stream.value(null);
  }
  final eventId = ref.watch(quizEventIdProvider);
  return ref.watch(quizTeamRepositoryProvider).watchById(eventId, teamId);
});

/// 現在出題中の問題を購読する。
///
/// イベントの `currentQuestionId` が未設定の間は `null` を流す。
final currentQuestionProvider = StreamProvider<QuizQuestion?>((ref) {
  final questionId = ref.watch(quizEventProvider).value?.currentQuestionId;
  if (questionId == null) {
    return Stream.value(null);
  }
  final eventId = ref.watch(quizEventIdProvider);
  return ref.watch(quizQuestionRepositoryProvider).watchById(eventId, questionId);
});

/// 現在の問題に対する自チームの回答を購読する。
///
/// 現在の問題または自チームが未確定の間、および出題前で回答ドキュメントが
/// 未作成の間は `null` を流す。
final teamAnswerProvider = StreamProvider<QuizAnswer?>((ref) {
  final questionId = ref.watch(currentQuestionProvider).value?.id;
  final teamId = ref.watch(myTeamProvider).value?.id;
  if (questionId == null || teamId == null) {
    return Stream.value(null);
  }
  final eventId = ref.watch(quizEventIdProvider);
  return ref.watch(quizAnswerRepositoryProvider).watchByQuestionAndTeam(eventId, questionId, teamId);
});

/// 全スポンサーを購読する。出題画面でスポンサー名を引くのに使う。
final quizSponsorsProvider = StreamProvider<List<Sponsor>>((ref) {
  return ref.watch(quizSponsorRepositoryProvider).watchAll();
});
