import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_repository.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_countdown.dart';
import 'package:dashboard/feature/quiz/ui/page/quiz_console_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final event = QuizEvent(
    id: 'event',
    title: const LocaleMap(ja: 'Quiz', en: 'Quiz'),
    status: QuizEventStatus.published,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  QuizQuestion question(String id, int order, [QuizQuestionStatus status = QuizQuestionStatus.draft]) => QuizQuestion(
    id: id,
    sponsorId: 'sponsor',
    order: order,
    title: LocaleMap(ja: '問題 $id', en: 'Question $id'),
    options: const [
      LocaleMap(ja: '○', en: 'True'),
      LocaleMap(ja: '×', en: 'False'),
    ],
    status: status,
  );
  final seated = QuizParticipant(id: 'seated', displayName: 'Seated', registeredAt: DateTime(2026), teamId: 'A');

  Future<_Questions> showConsole(WidgetTester tester, QuizEvent eventValue, List<QuizQuestion> questions) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _Questions();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizClockRepositoryProvider.overrideWithValue(_Clock()),
          quizEventProvider('event').overrideWith((_) => Stream.value(eventValue)),
          quizParticipantListProvider('event').overrideWith((_) => Stream.value([seated])),
          quizTeamListProvider('event').overrideWith((_) => Stream.value(quizTeamsFromParticipants([seated]))),
          quizQuestionListProvider('event').overrideWith((_) => Stream.value(questions)),
          quizSponsorListProvider.overrideWith((_) => Stream.value([])),
          quizAnswersByQuestionProvider.overrideWith((_, _) => Stream.value([])),
          quizOperationsRepositoryProvider.overrideWithValue(_Operations()),
          quizCheckInCodeProvider('event').overrideWith((_) => Stream.value(null)),
          quizQuestionRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: QuizConsolePage(eventId: 'event')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return repository;
  }

  Finder deleteButtonOf(String title) => find.descendant(
    of: find.ancestor(of: find.text(title), matching: find.byType(Card)),
    matching: find.byTooltip('問題を削除'),
  );

  testWidgets('deletes an unasked question after confirmation', (tester) async {
    final repository = await showConsole(tester, event, [question('first', 1), question('second', 2)]);
    expect(find.byTooltip('問題を削除'), findsNWidgets(2));

    await tester.tap(deleteButtonOf('問題 second'));
    await tester.pumpAndSettle();
    expect(find.text('問題 #2「問題 second」を削除します。正解と解説も削除され、元に戻せません。'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'キャンセル'));
    await tester.pumpAndSettle();
    expect(repository.deleted, isEmpty);

    await tester.tap(deleteButtonOf('問題 second'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '実行'));
    await tester.pumpAndSettle();
    expect(repository.deleted, [('event', 'second')]);
  });

  testWidgets('a failed deletion is reported on the console', (tester) async {
    final repository = await showConsole(tester, event, [question('first', 1)]);
    repository.error = StateError('出題済みの問題は削除できません。');
    await tester.tap(deleteButtonOf('問題 first'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '実行'));
    await tester.pumpAndSettle();
    expect(find.textContaining('問題削除 の完了を確認できませんでした'), findsOneWidget);
  });

  for (final status in [QuizEventStatus.inProgress, QuizEventStatus.finished]) {
    testWidgets('questions cannot be deleted once the event is $status', (tester) async {
      await showConsole(tester, event.copyWith(status: status), [
        question('first', 1, QuizQuestionStatus.revealed),
        question('second', 2),
      ]);
      expect(find.text('問題 second'), findsOneWidget);
      expect(find.byTooltip('問題を削除'), findsNothing);
    });
  }
}

class _Questions extends Fake implements QuizQuestionRepository {
  final deleted = <(String, String)>[];
  Object? error;

  @override
  Future<void> delete(String eventId, String questionId) async {
    if (error case final error?) throw error;
    deleted.add((eventId, questionId));
  }
}

class _Operations extends Fake implements QuizOperationsRepository {}

class _Clock implements QuizClockRepository {
  @override
  Future<QuizClock> synchronize() async => QuizClock(serverNow: DateTime(2026), elapsed: () => Duration.zero);
}
