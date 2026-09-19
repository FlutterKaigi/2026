import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_repository.dart';
import 'package:dashboard/feature/quiz/ui/page/quiz_console_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final event = QuizEvent(
    id: 'event',
    title: const LocaleMap(ja: 'Quiz', en: 'Quiz'),
    status: QuizEventStatus.inProgress,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  const draft = QuizQuestion(
    id: 'draft',
    sponsorId: 'sponsor',
    order: 2,
    title: LocaleMap(ja: '未出題の問題', en: 'Unasked question'),
    options: [
      LocaleMap(ja: '○', en: 'True'),
      LocaleMap(ja: '×', en: 'False'),
    ],
    status: QuizQuestionStatus.draft,
  );
  final revealed = draft.copyWith(id: 'revealed', order: 1, status: QuizQuestionStatus.revealed);

  Future<void> showConsole(WidgetTester tester, _Operations operations, List<QuizQuestion> questions) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizEventProvider('event').overrideWith((_) => Stream.value(event)),
          quizParticipantListProvider('event').overrideWith((_) => Stream.value([])),
          quizTeamListProvider('event').overrideWith((_) => Stream.value([])),
          quizQuestionListProvider('event').overrideWith((_) => Stream.value(questions)),
          quizSponsorListProvider.overrideWith((_) => Stream.value([])),
          quizEntryCodeProvider('event').overrideWith((_) => Stream.value('123456')),
          quizAnswersByQuestionProvider.overrideWith((_, _) => Stream.value([])),
          quizOperationsRepositoryProvider.overrideWithValue(operations),
        ],
        child: const MaterialApp(
          home: Scaffold(body: QuizConsolePage(eventId: 'event')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder finalizeButton() => find
      .ancestor(
        of: find.text('結果確定'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      )
      .first;

  testWidgets('finishing with drafts requires explicit confirmation that they are excluded', (tester) async {
    final operations = _Operations();
    await showConsole(tester, operations, [revealed, draft]);
    expect(tester.widget<FilledButton>(finalizeButton()).onPressed, isNotNull);
    await tester.ensureVisible(finalizeButton());
    await tester.tap(finalizeButton());
    await tester.pumpAndSettle();
    expect(find.textContaining('未出題の問題が 1 問残っています。'), findsOneWidget);
    expect(find.textContaining('発表済み 1 問だけで結果を確定'), findsOneWidget);
    expect(operations.finalized, 0);
    await tester.tap(find.text('実行'));
    await tester.pumpAndSettle();
    expect(operations.finalized, 1);
  });

  for (final active in [QuizQuestionStatus.reading, QuizQuestionStatus.closed]) {
    testWidgets('cannot finish while a question is $active even with a revealed question', (tester) async {
      await showConsole(tester, _Operations(), [revealed, draft.copyWith(status: active)]);
      expect(tester.widget<FilledButton>(finalizeButton()).onPressed, isNull);
    });
  }

  testWidgets('cannot finish without a revealed question', (tester) async {
    await showConsole(tester, _Operations(), [draft]);
    expect(tester.widget<FilledButton>(finalizeButton()).onPressed, isNull);
  });
}

class _Operations extends Fake implements QuizOperationsRepository {
  int finalized = 0;

  @override
  Future<void> finalizeEvent(String eventId) async => finalized++;
}
