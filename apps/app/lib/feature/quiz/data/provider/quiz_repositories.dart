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

/// 匿名認証を扱う認証リポジトリ。
final quizAuthRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

/// スポンサー情報のリポジトリ。
final quizSponsorRepositoryProvider = Provider<SponsorRepository>(
  (ref) => FirestoreSponsorRepository(),
);
