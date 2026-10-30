import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_repository.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_console_progress.dart';
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
    status: QuizEventStatus.draft,
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
  final waiting = QuizParticipant(id: 'waiting', displayName: 'Waiting', registeredAt: DateTime(2026));

  group('quizConsoleGuide', () {
    QuizConsoleGuide guide(
      QuizEventStatus status, {
      QuizTeamSelectionStatus selection = QuizTeamSelectionStatus.notStarted,
      List<QuizParticipant>? participants,
      List<QuizQuestion>? questions,
      bool canStart = false,
    }) => quizConsoleGuide(
      event: event.copyWith(status: status, teamSelectionStatus: selection),
      participants: participants ?? [seated],
      questions: questions ?? [question('first', 1)],
      canStart: canStart,
    );

    test('follows publish, registration and check-in in order', () {
      expect(guide(QuizEventStatus.draft, questions: []).action, isNull);
      expect(guide(QuizEventStatus.draft).step, QuizConsoleStep.prepare);
      expect(guide(QuizEventStatus.draft).action, QuizConsoleAction.publish);
      expect(guide(QuizEventStatus.published).step, QuizConsoleStep.registration);
      expect(guide(QuizEventStatus.published).action, QuizConsoleAction.openRegistration);
      expect(guide(QuizEventStatus.registration).action, QuizConsoleAction.closeRegistration);
      // 当日枠の受付再開中はチェックインが開いていても、先に参加登録を終了する。
      expect(
        guide(QuizEventStatus.registration, selection: QuizTeamSelectionStatus.open).action,
        QuizConsoleAction.closeRegistration,
      );
      expect(guide(QuizEventStatus.entryClosed).step, QuizConsoleStep.checkIn);
      expect(guide(QuizEventStatus.entryClosed).action, QuizConsoleAction.openCheckIn);
      final closing = guide(
        QuizEventStatus.entryClosed,
        selection: QuizTeamSelectionStatus.open,
        participants: [seated, waiting],
      );
      expect(closing.action, QuizConsoleAction.closeCheckIn);
      expect(closing.message, contains('未選択 1 人'));
    });

    test('waits for unselected attendees before the first question', () {
      final blocked = guide(
        QuizEventStatus.entryClosed,
        selection: QuizTeamSelectionStatus.closed,
        participants: [seated, waiting],
      );
      expect(blocked.step, QuizConsoleStep.checkIn);
      expect(blocked.action, isNull);
      expect(blocked.message, contains('未選択者を一括取消'));
      expect(
        guide(
          QuizEventStatus.entryClosed,
          selection: QuizTeamSelectionStatus.closed,
          participants: [],
        ).message,
        contains('受付を再開'),
      );
    });

    test('points at the lowest unasked question and then each question step', () {
      final questions = [question('second', 2), question('first', 1)];
      final first = guide(
        QuizEventStatus.entryClosed,
        selection: QuizTeamSelectionStatus.closed,
        questions: questions,
        canStart: true,
      );
      expect(first.step, QuizConsoleStep.questions);
      expect(first.action, QuizConsoleAction.presentQuestion);
      expect(first.questionId, 'first');

      for (final (status, action) in [
        (QuizQuestionStatus.reading, QuizConsoleAction.openQuestion),
        (QuizQuestionStatus.open, QuizConsoleAction.closeQuestion),
        (QuizQuestionStatus.closed, QuizConsoleAction.revealQuestion),
      ]) {
        final current = guide(
          QuizEventStatus.inProgress,
          questions: [question('first', 1, status), question('second', 2)],
        );
        expect(current.action, action);
        expect(current.questionId, 'first');
      }

      final next = guide(
        QuizEventStatus.inProgress,
        questions: [question('first', 1, QuizQuestionStatus.revealed), question('second', 2)],
      );
      expect(next.action, QuizConsoleAction.presentQuestion);
      expect(next.questionId, 'second');
    });

    test('finishes with the result after every question is revealed', () {
      final last = guide(QuizEventStatus.inProgress, questions: [question('first', 1, QuizQuestionStatus.revealed)]);
      expect(last.step, QuizConsoleStep.result);
      expect(last.action, QuizConsoleAction.finalize);
      expect(last.isDone(QuizConsoleStep.result), isFalse);

      final finished = guide(QuizEventStatus.finished);
      expect(finished.action, isNull);
      expect(QuizConsoleStep.values.every(finished.isDone), isTrue);
    });
  });

  testWidgets('the console shows the next step and fills only that button', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizClockRepositoryProvider.overrideWithValue(_Clock()),
          quizEventProvider('event').overrideWith(
            (_) => Stream.value(event.copyWith(status: QuizEventStatus.inProgress)),
          ),
          quizParticipantListProvider('event').overrideWith((_) => Stream.value([seated])),
          quizTeamListProvider('event').overrideWith((_) => Stream.value(quizTeamsFromParticipants([seated]))),
          quizQuestionListProvider('event').overrideWith(
            (_) => Stream.value([
              question('first', 1, QuizQuestionStatus.reading),
              question('second', 2),
            ]),
          ),
          quizSponsorListProvider.overrideWith((_) => Stream.value([])),
          quizAnswersByQuestionProvider.overrideWith((_, _) => Stream.value([])),
          quizOperationsRepositoryProvider.overrideWithValue(_Operations()),
          quizCheckInCodeProvider('event').overrideWith((_) => Stream.value(null)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: QuizConsolePage(eventId: 'event')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('問題 #1 を読み上げ終えたら「回答開始」を押します。'), findsOneWidget);
    expect(find.text('4. 出題'), findsOneWidget);
    // 次に押す「回答開始」だけを塗りつぶし、他の問題の「問題表示」は枠線のまま。
    expect(find.widgetWithText(FilledButton, '回答開始'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '回答開始'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '問題表示'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '問題表示'), findsNWidgets(2));
    // 延長は回答受付中・締切後だけに出す。
    expect(find.text('+30 秒'), findsNothing);
  });
}

class _Operations extends Fake implements QuizOperationsRepository {}

class _Clock implements QuizClockRepository {
  @override
  Future<QuizClock> synchronize() async => QuizClock(serverNow: DateTime(2026), elapsed: () => Duration.zero);
}
