import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Firestore 実装のリポジトリ群。テストでは `overrideWithValue` で差し替える。

/// クイズイベントのリポジトリ。
final quizEventRepositoryProvider = Provider<QuizEventRepository>(
  (ref) => FirestoreQuizEventRepository(),
);

/// クイズ参加者のリポジトリ。
final quizParticipantRepositoryProvider = Provider<QuizParticipantRepository>(
  (ref) => FirestoreQuizParticipantRepository(),
);

/// クイズチームのリポジトリ。
final quizTeamRepositoryProvider = Provider<QuizTeamRepository>(
  (ref) => FirestoreQuizTeamRepository(),
);

/// クイズ問題のリポジトリ。
final quizQuestionRepositoryProvider = Provider<QuizQuestionRepository>(
  (ref) => FirestoreQuizQuestionRepository(),
);

/// クイズ回答のリポジトリ。
final quizAnswerRepositoryProvider = Provider<QuizAnswerRepository>(
  (ref) => FirestoreQuizAnswerRepository(),
);

/// スポンサー情報のリポジトリ。
final quizSponsorRepositoryProvider = Provider<SponsorRepository>(
  (ref) => FirestoreSponsorRepository(),
);

/// サーバー時刻との同期。端末の時計設定に依存しないカウントダウンを供給する。
final quizClockRepositoryProvider = Provider<QuizClockRepository>(
  (ref) => FirebaseQuizClockRepository(),
);

final quizClockProvider = AsyncNotifierProvider.autoDispose<QuizClockController, QuizClock?>(
  QuizClockController.new,
);

class QuizClockController extends AsyncNotifier<QuizClock?> {
  @override
  Future<QuizClock> build() => ref.watch(quizClockRepositoryProvider).synchronize();

  void resynchronizeAfterInterruption() {
    // Keep the required synchronization across question/widget changes.
    state = const AsyncData(null);
    ref.invalidateSelf();
  }
}
