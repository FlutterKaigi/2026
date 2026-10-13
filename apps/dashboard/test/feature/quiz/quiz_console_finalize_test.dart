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

  Future<void> showConsole(
    WidgetTester tester,
    _Operations operations,
    List<QuizQuestion> questions, {
    QuizEvent? eventValue,
    List<QuizParticipant> people = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizEventProvider('event').overrideWith((_) => Stream.value(eventValue ?? event)),
          quizParticipantListProvider('event').overrideWith((_) => Stream.value(people)),
          quizTeamListProvider('event').overrideWith((_) => Stream.value(quizTeamsFromParticipants(people))),
          quizQuestionListProvider('event').overrideWith((_) => Stream.value(questions)),
          quizSponsorListProvider.overrideWith((_) => Stream.value([])),
          quizAnswersByQuestionProvider.overrideWith((_, _) => Stream.value([])),
          quizOperationsRepositoryProvider.overrideWithValue(operations),
          quizCheckInCodeProvider('event').overrideWith((_) => Stream.value('123456')),
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

  final waiting = QuizParticipant(id: 'waiting', displayName: 'Waiting', registeredAt: DateTime(2026));
  final checkedIn = waiting.copyWith(id: 'seated', displayName: 'Seated', teamId: 'A', checkedInAt: DateTime(2026));
  final arrived = waiting.copyWith(id: 'arrived', displayName: 'Arrived', checkedInAt: DateTime(2026));

  testWidgets('no-show cancellation is confirmed and reports the actual count', (tester) async {
    final operations = _Operations();
    await showConsole(
      tester,
      operations,
      [draft],
      eventValue: event.copyWith(
        status: QuizEventStatus.entryClosed,
        teamSelectionStatus: QuizTeamSelectionStatus.open,
      ),
      people: [waiting, checkedIn],
    );
    expect(find.text('参加表明 2 人 / チェックイン済み 1 人 / チーム選択済み 1 人 / 未選択 1 人（未チェックインを含む）'), findsOneWidget);
    final button = find.widgetWithText(OutlinedButton, '未選択者を一括取消');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(operations.cancelled, 0);
    await tester.tap(find.text('実行'));
    await tester.pumpAndSettle();
    expect(operations.cancelled, 1);
    expect(find.text('1 人の参加を取り消しました'), findsOneWidget);
  });

  for (final state in [
    (QuizEventStatus.registration, QuizTeamSelectionStatus.open),
    (QuizEventStatus.entryClosed, QuizTeamSelectionStatus.notStarted),
  ]) {
    testWidgets('no-show cancellation is disabled in $state', (tester) async {
      await showConsole(
        tester,
        _Operations(),
        [],
        eventValue: event.copyWith(
          status: state.$1,
          teamSelectionStatus: state.$2,
        ),
        people: [waiting],
      );
      expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '未選択者を一括取消')).onPressed, isNull);
    });
  }

  testWidgets('check-in starts only after registration closes', (tester) async {
    for (final (status, enabled) in [(QuizEventStatus.registration, false), (QuizEventStatus.entryClosed, true)]) {
      await showConsole(tester, _Operations(), [], eventValue: event.copyWith(status: status));
      final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'チェックインを開始'));
      expect(button.onPressed != null, enabled);
      expect(find.text('チェックインは参加登録を終了してから開始できます。'), enabled ? findsNothing : findsOneWidget);
      expect(find.text('123456'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('during check-in the console shows the code, reissues it, and tells attendee states apart', (
    tester,
  ) async {
    final operations = _Operations();
    await showConsole(
      tester,
      operations,
      [],
      eventValue: event.copyWith(
        status: QuizEventStatus.registration,
        teamSelectionStatus: QuizTeamSelectionStatus.open,
      ),
      people: [waiting, arrived, checkedIn],
    );
    expect(find.text('123456'), findsOneWidget);
    expect(find.text('参加表明 3 人 / チェックイン済み 2 人 / チーム選択済み 1 人 / 未選択 2 人（未チェックインを含む）'), findsOneWidget);
    final reissue = find.widgetWithText(OutlinedButton, 'コードを再発行');
    await tester.ensureVisible(reissue);
    await tester.tap(reissue);
    await tester.pumpAndSettle();
    await tester.tap(find.text('実行'));
    await tester.pumpAndSettle();
    expect(operations.regenerated, 1);

    final roster = find.textContaining('参加者の確認・取消');
    await tester.ensureVisible(roster);
    await tester.tap(roster);
    await tester.pumpAndSettle();
    expect(find.text('未チェックイン / waiting'), findsOneWidget);
    expect(find.text('チェックイン済み・未選択 / arrived'), findsOneWidget);
    expect(find.text('チーム A / seated'), findsOneWidget);
  });

  testWidgets('first question needs closed selection and no unselected attendees', (tester) async {
    for (final people in [
      [checkedIn, waiting],
      [checkedIn],
    ]) {
      await showConsole(
        tester,
        _Operations(),
        [draft],
        eventValue: event.copyWith(
          status: QuizEventStatus.entryClosed,
          teamSelectionStatus: QuizTeamSelectionStatus.closed,
        ),
        people: people,
      );
      final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '問題表示'));
      expect(button.onPressed != null, people.length == 1);
      await tester.pumpWidget(const SizedBox());
    }
  });

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
  int cancelled = 0;
  int regenerated = 0;

  @override
  Future<void> regenerateCheckInCode(String eventId) async => regenerated++;

  @override
  Future<int> removeUnselectedParticipants(String eventId) async {
    cancelled++;
    return 1;
  }

  @override
  Future<void> finalizeEvent(String eventId) async => finalized++;
}
