import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/ui/page/quiz_projection_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final event = QuizEvent(
    id: 'event',
    title: const LocaleMap(ja: 'Quiz', en: 'Quiz'),
    status: QuizEventStatus.inProgress,
    currentQuestionId: 'question',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  const question = QuizQuestion(
    id: 'question',
    sponsorId: 'sponsor',
    order: 1,
    title: LocaleMap(ja: '公開の問題', en: 'Question'),
    options: [
      LocaleMap(ja: '○', en: 'True'),
      LocaleMap(ja: '×', en: 'False'),
    ],
    status: QuizQuestionStatus.reading,
    // Even an accidentally present public answer is hidden before reveal.
    correctOptionIndex: 1,
    explanation: LocaleMap(ja: 'まだ秘密の解説', en: 'Private explanation'),
  );

  testWidgets('reading projection shows question without code, answer, or countdown', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizEventProvider('event').overrideWith((_) => Stream.value(event)),
          quizQuestionProvider((eventId: 'event', questionId: 'question')).overrideWith((_) => Stream.value(question)),
          quizEntryCodeProvider('event').overrideWith((_) => throw StateError('Projection must not read entry code')),
          quizQuestionSecretProvider((
            eventId: 'event',
            questionId: 'question',
          )).overrideWith((_) => throw StateError('Projection must not read secrets')),
          quizQuestionListProvider('event').overrideWith((_) => throw StateError('Projection must not read drafts')),
        ],
        child: const MaterialApp(home: QuizProjectionPage(eventId: 'event')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('公開の問題'), findsOneWidget);
    expect(find.text('まだ秘密の解説'), findsNothing);
    expect(find.textContaining('✓ 正解'), findsNothing);
    expect(find.textContaining('残り'), findsNothing);
    expect(find.text('読み上げ後に回答受付を開始します。'), findsOneWidget);
  });

  testWidgets('final projection keeps every team tied for first place', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizEventProvider('event').overrideWith(
            (_) => Stream.value(event.copyWith(status: QuizEventStatus.finished, currentQuestionId: null)),
          ),
          quizTeamListProvider('event').overrideWith(
            (_) => Stream.value([
              const QuizTeam(id: 'a', tableNumber: 1, name: 'Alpha', score: 80, rank: 1),
              const QuizTeam(id: 'b', tableNumber: 2, name: 'Bravo', score: 80, rank: 1),
              const QuizTeam(id: 'c', tableNumber: 3, name: 'Charlie', score: 80, rank: 1),
            ]),
          ),
        ],
        child: const MaterialApp(home: QuizProjectionPage(eventId: 'event')),
      ),
    );
    await tester.pumpAndSettle();
    for (final name in ['Alpha', 'Bravo', 'Charlie']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('1 位'), findsNWidgets(3));
  });
}
