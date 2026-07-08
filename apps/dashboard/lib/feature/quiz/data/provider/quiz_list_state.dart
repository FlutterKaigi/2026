import 'package:dashboard/feature/quiz/data/provider/quiz_repository.dart';
import 'package:dashboard/feature/sponsor/data/provider/sponsor_repository.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// クイズイベント一覧（作成日時降順）。
final quizEventListProvider = StreamProvider<List<QuizEvent>>(
  (ref) => ref.watch(quizEventRepositoryProvider).watchAll(),
);

/// 単一クイズイベントのリアルタイム購読。
final quizEventProvider = StreamProvider.family<QuizEvent?, String>(
  (ref, eventId) => ref.watch(quizEventRepositoryProvider).watchById(eventId),
);

/// イベント配下の参加者一覧（登録順）。参加者数の表示にも使う。
final quizParticipantListProvider = StreamProvider.family<List<QuizParticipant>, String>(
  (ref, eventId) => ref.watch(quizParticipantRepositoryProvider).watchAll(eventId),
);

/// イベント配下のチーム一覧（tableNumber 昇順）。
final quizTeamListProvider = StreamProvider.family<List<QuizTeam>, String>(
  (ref, eventId) => ref.watch(quizTeamRepositoryProvider).watchAll(eventId),
);

/// イベント配下の問題一覧（order 昇順）。
final quizQuestionListProvider = StreamProvider.family<List<QuizQuestion>, String>(
  (ref, eventId) => ref.watch(quizQuestionRepositoryProvider).watchAll(eventId),
);

/// 特定の問題の全チーム回答（回答数カウント用）。
///
/// family の引数は (eventId, questionId)。Riverpod の family は 1 引数のため
/// レコードで束ねる。
final quizAnswersByQuestionProvider = StreamProvider.family<List<QuizAnswer>, ({String eventId, String questionId})>(
  (ref, args) => ref.watch(quizAnswerRepositoryProvider).watchByQuestion(args.eventId, args.questionId),
);

/// スポンサー名の解決に使う一覧。スポンサー feature の repository を再利用する。
final quizSponsorListProvider = StreamProvider<List<Sponsor>>(
  (ref) => ref.watch(sponsorRepositoryProvider).watchAll(),
);
