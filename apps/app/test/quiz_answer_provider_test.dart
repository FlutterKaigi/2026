import 'dart:async';

import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('answer subscription starts only when reading transitions to open for the same question', () async {
    final questions = StreamController<QuizQuestion?>();
    final repository = _Answers();
    final container = ProviderContainer(
      overrides: [
        quizEventIdProvider.overrideWithValue('event'),
        currentQuestionProvider.overrideWith((_) => questions.stream),
        myTeamProvider.overrideWith((_) => Stream.value(const QuizTeam(id: 'team', name: 'Team', tableNumber: 1))),
        quizAnswerRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await questions.close();
    });
    final receivedAnswer = Completer<QuizAnswer>();
    final openedQuestion = Completer<void>();
    container.listen(teamAnswerProvider, (_, next) {
      final answer = next.value;
      if (answer != null && !receivedAnswer.isCompleted) {
        receivedAnswer.complete(answer);
      }
    });
    container.listen(currentQuestionProvider, (_, next) {
      if (next.value?.status == QuizQuestionStatus.open && !openedQuestion.isCompleted) {
        openedQuestion.complete();
      }
    });
    const reading = QuizQuestion(
      id: 'question',
      sponsorId: 'sponsor',
      order: 1,
      title: LocaleMap(ja: '問題', en: 'Question'),
      status: QuizQuestionStatus.reading,
    );
    questions.add(reading);
    await container.read(currentQuestionProvider.future);
    await container.read(myTeamProvider.future);
    await container.pump();
    expect(repository.watchedQuestions, isEmpty);
    expect(container.read(teamAnswerProvider).value, isNull);
    questions.add(reading.copyWith(status: QuizQuestionStatus.open));
    await openedQuestion.future.timeout(const Duration(seconds: 5));
    await container.pump();
    final answer = await receivedAnswer.future.timeout(const Duration(seconds: 5));
    expect(repository.watchedQuestions, ['question']);
    expect(answer.id, 'question_team');
  });
}

class _Answers extends Fake implements QuizAnswerRepository {
  final watchedQuestions = <String>[];

  @override
  Stream<QuizAnswer?> watchByQuestionAndTeam(String eventId, String questionId, String teamId) {
    watchedQuestions.add(questionId);
    return Stream.value(QuizAnswer(id: '${questionId}_$teamId', questionId: questionId, teamId: teamId));
  }
}
