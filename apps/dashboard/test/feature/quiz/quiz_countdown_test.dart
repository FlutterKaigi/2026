import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_repository.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_countdown.dart';
import 'package:dashboard/feature/quiz/ui/page/quiz_console_page.dart';
import 'package:dashboard/feature/quiz/ui/page/quiz_projection_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final anchor = DateTime.utc(2026, 11, 13, 5);
final event = QuizEvent(
  id: 'event',
  title: const LocaleMap(ja: 'クイズ', en: 'Quiz'),
  status: QuizEventStatus.inProgress,
  currentQuestionId: 'question1',
  createdAt: anchor,
  updatedAt: anchor,
);
QuizQuestion question(String id, QuizQuestionStatus status, int closesAfter) => QuizQuestion(
  id: id,
  sponsorId: 'sponsor',
  order: id == 'question1' ? 1 : 2,
  title: LocaleMap(ja: '$id の問題', en: 'Question'),
  options: const [
    LocaleMap(ja: '○', en: 'True'),
    LocaleMap(ja: '×', en: 'False'),
  ],
  status: status,
  durationSeconds: 15,
  closesAt: status == QuizQuestionStatus.reading ? null : anchor.add(Duration(seconds: closesAfter)),
);

void main() {
  Future<void> showCountdown(WidgetTester tester, _Clock clock, {int durationSeconds = 90}) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [quizClockRepositoryProvider.overrideWithValue(clock)],
        child: MaterialApp(
          home: Scaffold(
            body: QuizCountdown(closesAt: anchor.add(Duration(seconds: durationSeconds))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('fractional remaining seconds round up and never show an early deadline', (tester) async {
    final clock = _Clock();
    await showCountdown(tester, clock, durationSeconds: 15);
    expect(find.text('残り 0:15'), findsOneWidget);
    clock.elapsed = const Duration(milliseconds: 500);
    await tester.pump(const Duration(milliseconds: 500));
    await showCountdown(tester, clock, durationSeconds: 15);
    expect(clock.calls, 1);
    expect(
      find.text('残り 0:15'),
      findsOneWidget,
      reason: '14.5 seconds remaining must agree with the attendee countdown',
    );
    clock.elapsed = const Duration(milliseconds: 14500);
    await tester.pump(const Duration(seconds: 14));
    expect(find.text('残り 0:01'), findsOneWidget);
    expect(find.text('回答時間終了'), findsNothing);
    clock.elapsed = const Duration(seconds: 15);
    await showCountdown(tester, clock, durationSeconds: 15);
    expect(find.text('回答時間終了'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final projection in [true, false]) {
    testWidgets(
      '${projection ? "projection" : "console"} synchronizes during reading and starts answers without another clock request',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final clock = _Clock();
        final initial = Completer<QuizClock>();
        clock.next = initial.future;
        final questions = StreamController<QuizQuestion>()..add(question('question1', QuizQuestionStatus.reading, 0));
        addTearDown(questions.close);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              quizEventProvider('event').overrideWith((_) => Stream.value(event)),
              quizClockRepositoryProvider.overrideWithValue(clock),
              if (projection) ...[
                quizQuestionProvider((eventId: 'event', questionId: 'question1')).overrideWith((_) => questions.stream),
                quizSponsorListProvider.overrideWith((_) => Stream.value([])),
              ] else ...[
                quizQuestionListProvider('event').overrideWith((_) => questions.stream.map((value) => [value])),
                quizParticipantListProvider('event').overrideWith((_) => Stream.value([])),
                quizTeamListProvider('event').overrideWith((_) => Stream.value([])),
                quizAnswersByQuestionProvider.overrideWith((_, _) => Stream.value([])),
                quizSponsorListProvider.overrideWith((_) => Stream.value([])),
                quizOperationsRepositoryProvider.overrideWithValue(_Operations()),
              ],
            ],
            child: MaterialApp(
              home: projection
                  ? const QuizProjectionPage(eventId: 'event')
                  : const Scaffold(body: QuizConsolePage(eventId: 'event')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(clock.calls, 1, reason: 'Synchronization must start while the moderator is still reading');
        expect(find.text('question1 の問題'), findsOneWidget);
        expect(find.textContaining('残り '), findsNothing);
        expect(find.text('時刻を同期中…'), findsNothing);
        clock.elapsed = const Duration(seconds: 6);
        await tester.pump(const Duration(seconds: 6));
        initial.complete(
          QuizClock(serverNow: anchor.add(clock.elapsed), elapsed: () => clock.elapsed - const Duration(seconds: 6)),
        );
        await tester.pumpAndSettle();
        for (final seconds in [30, 60, 90]) {
          final elapsed = Duration(seconds: seconds);
          final advance = elapsed - clock.elapsed;
          clock.elapsed = elapsed;
          await tester.pump(advance);
          await tester.pumpAndSettle();
        }
        expect(clock.calls, 4, reason: 'Long reading stages keep recalibrating the clock');
        questions.add(question('question1', QuizQuestionStatus.open, 105));
        await tester.pumpAndSettle();
        expect(clock.calls, 4, reason: 'Opening answers must reuse the prepared clock');
        // The projection shows the label and the large m:ss separately.
        expect(find.text(projection ? '0:15' : '残り 0:15'), findsOneWidget);
        expect(find.text('時刻を同期中…'), findsNothing);
        expect(find.text('残り時間を確認中…'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('periodic resynchronization keeps the valid countdown visible', (tester) async {
    final clock = _Clock();
    await showCountdown(tester, clock);
    final pending = Completer<QuizClock>();
    clock.next = pending.future;
    clock.elapsed = const Duration(seconds: 30);
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(clock.calls, 2);
    expect(find.text('残り 1:00'), findsOneWidget);
    clock.elapsed = const Duration(seconds: 33);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('残り 0:57'), findsOneWidget);
    pending.complete(QuizClock(serverNow: anchor.add(const Duration(seconds: 33)), elapsed: () => Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('残り 0:57'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a failed periodic refresh can use a fresh clock but never an expired one', (tester) async {
    final clock = _Clock();
    await showCountdown(tester, clock);
    clock.failure = FirebaseFunctionsException(code: 'unavailable', message: 'Clock request interrupted');
    clock.elapsed = const Duration(seconds: 30);
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('残り 1:00'), findsOneWidget);
    clock.elapsed = const Duration(seconds: 60);
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('時刻同期に失敗しました（再接続待ち）'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('resume still requires a new clock before showing a countdown', (tester) async {
    final clock = _Clock();
    await showCountdown(tester, clock);
    final pending = Completer<QuizClock>();
    clock.next = pending.future;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.text('時刻を同期中…'), findsOneWidget);
    pending.complete(QuizClock(serverNow: anchor.add(const Duration(seconds: 20)), elapsed: () => Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('残り 1:10'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('projection resynchronizes immediately when the next question starts after a long intermission', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final clock = _Clock();
    final events = StreamController<QuizEvent>.broadcast();
    final question1 = StreamController<QuizQuestion>.broadcast();
    final question2 = StreamController<QuizQuestion>.broadcast();
    final container = ProviderContainer(
      overrides: [
        quizEventProvider('event').overrideWith((_) => events.stream),
        quizQuestionProvider((eventId: 'event', questionId: 'question1')).overrideWith((_) => question1.stream),
        quizQuestionProvider((eventId: 'event', questionId: 'question2')).overrideWith((_) => question2.stream),
        quizClockRepositoryProvider.overrideWithValue(clock),
        quizSponsorListProvider.overrideWith((_) => Stream.value([])),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await events.close();
      await question1.close();
      await question2.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: QuizProjectionPage(eventId: 'event')),
      ),
    );
    await tester.pump();
    events.add(event);
    await tester.pump();
    await tester.pump();
    question1.add(question('question1', QuizQuestionStatus.open, 15));
    await tester.pumpAndSettle();
    expect(clock.calls, 1);
    expect(find.text('0:15'), findsOneWidget);

    clock.elapsed = const Duration(seconds: 15);
    await tester.pump(const Duration(seconds: 15));
    question1.add(question('question1', QuizQuestionStatus.revealed, 15));
    await tester.pumpAndSettle();
    expect(find.byType(QuizCountdown), findsNothing);
    // The moderator spends 70 seconds explaining the answer and introducing Q2.
    clock.elapsed = const Duration(seconds: 85);
    await tester.pump(const Duration(seconds: 70));
    events.add(event.copyWith(currentQuestionId: 'question2'));
    await tester.pump();
    await tester.pump();
    question2.add(question('question2', QuizQuestionStatus.reading, 100));
    await tester.pumpAndSettle();
    expect(find.text('question2 の問題'), findsOneWidget);
    question2.add(question('question2', QuizQuestionStatus.open, 100));
    await tester.pumpAndSettle();
    expect(find.text('0:15'), findsOneWidget);
    expect(clock.calls, 2, reason: 'The new question must synchronize before the first 30-second periodic tick');
    for (var second = 1; second <= 15; second++) {
      clock.elapsed = Duration(seconds: 85 + second);
      await tester.pump(const Duration(seconds: 1));
      // Once the deadline passes, the projection says answers are closed before the moderator closes them.
      final shown = second == 15 ? '正解発表をお待ちください' : '0:${(15 - second).toString().padLeft(2, '0')}';
      expect(find.text(shown), findsOneWidget);
      expect(clock.calls, 2);
    }
    expect(clock.now, anchor.add(const Duration(seconds: 100)));
    expect(find.text('question2 の問題'), findsOneWidget);
    clock.elapsed = const Duration(seconds: 115);
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();
    expect(clock.calls, 3);
    expect(find.text('正解発表をお待ちください'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

class _Clock implements QuizClockRepository {
  int calls = 0;
  Duration elapsed = Duration.zero;
  Future<QuizClock>? next;
  Exception? failure;
  DateTime get now => anchor.add(elapsed);
  @override
  Future<QuizClock> synchronize() async {
    calls++;
    if (failure case final error?) throw error;
    if (next case final pending?) {
      next = null;
      return pending;
    }
    final sampledElapsed = elapsed;
    return QuizClock(serverNow: now, elapsed: () => elapsed - sampledElapsed);
  }
}

class _Operations extends Fake implements QuizOperationsRepository {}
