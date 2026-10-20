import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/component/quiz_option_card.dart';
import 'package:app/feature/quiz/ui/component/quiz_question_view.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';

void main() {
  final serverNow = DateTime.utc(2026);
  const team = QuizTeam(id: 'A', name: 'A', tableNumber: 1);
  const unanswered = QuizAnswer(id: 'q1_A', questionId: 'q1', teamId: 'A');
  late StreamController<QuizAnswer?> answers;
  late _Clock clock;
  late _Answers repository;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    answers = StreamController<QuizAnswer?>()..add(unanswered);
    clock = _Clock(serverNow);
    repository = _Answers();
  });
  tearDown(() => answers.close());

  QuizQuestion question(String id) => QuizQuestion(
    id: id,
    sponsorId: 'sponsor',
    order: 1,
    title: LocaleMap(ja: '問題 $id', en: 'Question $id'),
    options: const [
      LocaleMap(ja: '選択肢1', en: 'First'),
      LocaleMap(ja: '選択肢2', en: 'Second'),
    ],
    status: QuizQuestionStatus.open,
    closesAt: serverNow.add(const Duration(seconds: 90)),
  );

  Future<void> show(
    WidgetTester tester, {
    ValueNotifier<String>? currentQuestion,
    ValueNotifier<QuizQuestion>? questionState,
  }) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          retry: (_, _) => null,
          overrides: [
            quizEventIdProvider.overrideWithValue('event'),
            quizUserProvider.overrideWithValue(AsyncData(FakeUser())),
            quizSponsorsProvider.overrideWith((_) => Stream.value(<Sponsor>[])),
            teamAnswerProvider.overrideWith((_) => answers.stream),
            quizAnswerRepositoryProvider.overrideWithValue(repository),
            quizClockRepositoryProvider.overrideWithValue(clock),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) =>
                MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
            home: Scaffold(
              body: questionState != null
                  ? ValueListenableBuilder(
                      valueListenable: questionState,
                      builder: (_, value, _) => QuizQuestionView(key: ValueKey(value.id), question: value, team: team),
                    )
                  : currentQuestion == null
                  ? QuizQuestionView(key: const ValueKey('q1'), question: question('q1'), team: team)
                  : ValueListenableBuilder(
                      valueListenable: currentQuestion,
                      builder: (_, id, _) => QuizQuestionView(key: ValueKey(id), question: question(id), team: team),
                    ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester) => tester.widget<QuizOptionCard>(find.byType(QuizOptionCard).first).enabled;

  testWidgets('reopening an expired short question shows all extended time and bounds the progress bar', (
    tester,
  ) async {
    final state = ValueNotifier(
      question('q1').copyWith(durationSeconds: 15, closesAt: serverNow.add(const Duration(seconds: 15))),
    );
    addTearDown(state.dispose);
    await show(tester, questionState: state);
    expect(find.text('15'), findsOneWidget);
    clock.elapsed = const Duration(seconds: 16);
    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
    expect(enabled(tester), isFalse);
    state.value = state.value.copyWith(closesAt: serverNow.add(const Duration(seconds: 46)));
    await tester.pumpAndSettle();
    expect(find.text('30'), findsOneWidget);
    expect(enabled(tester), isTrue);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 1);
    clock.elapsed = const Duration(seconds: 20);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('26'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an extended long question shows the server deadline beyond its original duration', (tester) async {
    final state = ValueNotifier(
      question('q1').copyWith(durationSeconds: 180, closesAt: serverNow.add(const Duration(seconds: 210))),
    );
    addTearDown(state.dispose);
    await show(tester, questionState: state);
    expect(find.text('210'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 1);
    expect(enabled(tester), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('periodic synchronization preserves the final seconds of a short answer window', (tester) async {
    final state = ValueNotifier(
      question('q1').copyWith(status: QuizQuestionStatus.reading, durationSeconds: 15, closesAt: null),
    );
    addTearDown(state.dispose);
    await show(tester, questionState: state);
    clock.elapsed = const Duration(seconds: 20);
    await tester.pump(const Duration(seconds: 20));
    state.value = state.value.copyWith(
      status: QuizQuestionStatus.open,
      closesAt: serverNow.add(const Duration(seconds: 35)),
    );
    await tester.pumpAndSettle();
    expect(enabled(tester), isTrue);
    expect(find.text('15'), findsOneWidget);
    final pending = Completer<QuizClock>();
    clock.next = pending.future;
    clock.elapsed = const Duration(seconds: 30);
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();
    expect(clock.calls, 2);
    expect(enabled(tester), isTrue);
    expect(find.text('5'), findsOneWidget);
    clock.elapsed = const Duration(seconds: 33);
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('選択肢1'));
    await tester.pump();
    expect(repository.calls, [('q1', 0)]);
    clock.elapsed = const Duration(seconds: 36);
    pending.complete(QuizClock(serverNow: serverNow.add(clock.elapsed), elapsed: () => Duration.zero));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(enabled(tester), isFalse);
    expect(find.text(t.quiz.question.locked), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a failed periodic synchronization keeps a fresh clock but never an expired one', (tester) async {
    await show(tester);
    clock.error = FirebaseFunctionsException(code: 'unavailable', message: 'Clock request interrupted');
    clock.elapsed = const Duration(seconds: 30);
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(enabled(tester), isTrue);
    expect(find.text('60'), findsOneWidget);
    clock.elapsed = const Duration(seconds: 60);
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(enabled(tester), isFalse);
    expect(find.text(t.quiz.question.connectionUnavailable), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('resume requires a new synchronization even when the previous clock is fresh', (tester) async {
    await show(tester);
    final pending = Completer<QuizClock>();
    clock.next = pending.future;
    clock.elapsed = const Duration(seconds: 20);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(enabled(tester), isFalse);
    expect(find.text(t.quiz.question.synchronizing), findsOneWidget);
    await tester.tap(find.text('選択肢1'));
    expect(repository.calls, isEmpty);
    pending.complete(QuizClock(serverNow: serverNow.add(const Duration(seconds: 25)), elapsed: () => Duration.zero));
    await tester.pumpAndSettle();
    expect(enabled(tester), isTrue);
    expect(find.text('65'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an old periodic response cannot unlock answers while the resume synchronization is pending', (
    tester,
  ) async {
    await show(tester);
    final periodic = Completer<QuizClock>();
    clock.next = periodic.future;
    clock.elapsed = const Duration(seconds: 30);
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    final resumed = Completer<QuizClock>();
    clock.next = resumed.future;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(clock.calls, 3);
    expect(enabled(tester), isFalse);
    periodic.complete(QuizClock(serverNow: serverNow.add(const Duration(seconds: 31)), elapsed: () => Duration.zero));
    await tester.pumpAndSettle();
    expect(enabled(tester), isFalse);
    resumed.complete(QuizClock(serverNow: serverNow.add(const Duration(seconds: 32)), elapsed: () => Duration.zero));
    await tester.pumpAndSettle();
    expect(enabled(tester), isTrue);
    expect(find.text('58'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('changing questions cannot bypass the required resume synchronization', (tester) async {
    final current = ValueNotifier('q1');
    addTearDown(current.dispose);
    await show(tester, currentQuestion: current);
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
    expect(enabled(tester), isFalse);
    current.value = 'q2';
    answers.add(unanswered.copyWith(id: 'q2_A', questionId: 'q2'));
    await tester.pumpAndSettle();
    expect(find.text('問題 q2'), findsOneWidget);
    expect(enabled(tester), isFalse);
    await tester.tap(find.text('選択肢1'));
    expect(repository.calls, isEmpty);
    pending.complete(QuizClock(serverNow: serverNow.add(const Duration(seconds: 20)), elapsed: () => Duration.zero));
    await tester.pumpAndSettle();
    expect(enabled(tester), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cache -> reconnect waits for a new clock then enables answer', (tester) async {
    await show(tester);
    expect(enabled(tester), isTrue);
    final calls = clock.calls;
    answers.add(unanswered.copyWith(selectedOptionIndex: 1, isFromCache: true));
    await tester.pumpAndSettle();
    expect(enabled(tester), isFalse);
    expect(find.text(t.quiz.question.cached), findsOneWidget);
    final pending = Completer<QuizClock>();
    clock.next = pending.future;
    answers.add(unanswered.copyWith(selectedOptionIndex: 1));
    await tester.pump();
    await tester.pump();
    expect(clock.calls, calls + 1);
    expect(enabled(tester), isFalse);
    pending.complete(QuizClock(serverNow: serverNow.add(const Duration(seconds: 20)), elapsed: () => Duration.zero));
    await tester.pumpAndSettle();
    expect(enabled(tester), isTrue);
    expect(find.text('70'), findsOneWidget);
    expect(tester.widget<QuizOptionCard>(find.byType(QuizOptionCard).at(1)).state, QuizOptionState.selected);
  });

  testWidgets('resume after server deadline never re-enables stale answer input', (tester) async {
    await show(tester);
    expect(enabled(tester), isTrue);
    final before = clock.calls;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    clock.anchor = serverNow.add(const Duration(seconds: 91));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(clock.calls, greaterThan(before));
    expect(enabled(tester), isFalse);
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.text('選択肢1'));
    expect(repository.calls, isEmpty);
  });

  testWidgets('resumed clock failure recovers through retry without reopening page', (tester) async {
    await show(tester);
    clock.error = FirebaseFunctionsException(code: 'unavailable', message: 'Injected offline');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(enabled(tester), isFalse);
    expect(find.text(t.quiz.question.connectionUnavailable), findsOneWidget);
    clock.error = null;
    clock.anchor = serverNow.add(const Duration(seconds: 25));
    await tester.tap(find.text(t.common.retry));
    await tester.pumpAndSettle();
    expect(enabled(tester), isTrue);
    expect(find.text('65'), findsOneWidget);
  });

  testWidgets('answer listener error recovers when live snapshot returns', (tester) async {
    await show(tester);
    answers.addError(StateError('Injected listener interruption'));
    await tester.pumpAndSettle();
    expect(enabled(tester), isFalse);
    expect(find.text(t.quiz.question.connectionUnavailable), findsOneWidget);
    answers.add(unanswered.copyWith(selectedOptionIndex: 0));
    await tester.pumpAndSettle();
    expect(enabled(tester), isTrue);
    expect(tester.widget<QuizOptionCard>(find.byType(QuizOptionCard).first).state, QuizOptionState.selected);
  });

  testWidgets('late acknowledgement from previous question cannot confirm next question', (tester) async {
    final current = ValueNotifier('q1');
    addTearDown(current.dispose);
    repository.pending = Completer<void>();
    await show(tester, currentQuestion: current);
    await tester.tap(find.text('選択肢1'));
    await tester.pump();
    expect(find.text(t.quiz.question.sending), findsOneWidget);
    current.value = 'q2';
    answers.add(unanswered.copyWith(id: 'q2_A', questionId: 'q2'));
    await tester.pumpAndSettle();
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.question.accepted), findsNothing);
    expect(find.text(t.quiz.question.sending), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _Clock implements QuizClockRepository {
  _Clock(this.anchor);
  DateTime anchor;
  int calls = 0;
  Duration elapsed = Duration.zero;
  Future<QuizClock>? next;
  Exception? error;
  @override
  Future<QuizClock> synchronize() async {
    calls++;
    if (error case final failure?) {
      throw failure;
    }
    if (next case final pending?) {
      next = null;
      return pending;
    }
    final sampledElapsed = elapsed;
    return QuizClock(serverNow: anchor.add(elapsed), elapsed: () => elapsed - sampledElapsed);
  }
}

class _Answers extends Fake implements QuizAnswerRepository {
  final calls = <(String, int)>[];
  Completer<void>? pending;
  @override
  Future<void> submit(
    String eventId,
    String questionId,
    String teamId, {
    required int selectedOptionIndex,
    String? uid,
  }) async {
    calls.add((questionId, selectedOptionIndex));
    await pending?.future;
  }
}
