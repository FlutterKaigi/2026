import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final quizEventRepositoryProvider = Provider<QuizEventRepository>(
  (_) => FirestoreQuizEventRepository(),
);

final quizParticipantRepositoryProvider = Provider<QuizParticipantRepository>(
  (_) => FirestoreQuizParticipantRepository(),
);

final quizTeamRepositoryProvider = Provider<QuizTeamRepository>(
  (_) => FirestoreQuizTeamRepository(),
);

final quizQuestionRepositoryProvider = Provider<QuizQuestionRepository>(
  (_) => FirestoreQuizQuestionRepository(),
);

final quizAnswerRepositoryProvider = Provider<QuizAnswerRepository>(
  (_) => FirestoreQuizAnswerRepository(),
);

final quizOperationsRepositoryProvider = Provider<QuizOperationsRepository>(
  (_) => FirestoreQuizOperationsRepository(),
);
