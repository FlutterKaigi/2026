import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/designsystem/theme/app_theme.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/component/quiz_option_card.dart';
import 'package:app/feature/quiz/ui/component/quiz_question_view.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';

void main() {
  final serverNow = DateTime.utc(2020);
  const team = QuizTeam(
    id: 'team',
    name: 'Team',
    tableNumber: 1,
    members: [QuizTeamMember(uid: 'hanako', displayName: 'はなこ')],
  );
  const unanswered = QuizAnswer(id: 'question_team', questionId: 'question', teamId: 'team');
  late _Answers repository;
  late _Clock clock;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    repository = _Answers();
    clock = _Clock(serverNow);
  });

  Widget subject({
    QuizQuestionStatus status = QuizQuestionStatus.open,
    QuizAnswer answer = unanswered,
    Stream<QuizAnswer?>? answers,
    ThemeData? theme,
  }) {
    return TranslationProvider(
      child: ProviderScope(
        retry: (_, _) => null,
        overrides: [
          quizEventIdProvider.overrideWithValue('event'),
          quizUserProvider.overrideWithValue(AsyncData(FakeUser())),
          quizSponsorsProvider.overrideWith((_) => Stream.value(<Sponsor>[])),
          teamAnswerProvider.overrideWith((_) => answers ?? Stream.value(answer)),
          quizAnswerRepositoryProvider.overrideWithValue(repository),
          quizClockRepositoryProvider.overrideWithValue(clock),
        ],
        child: MaterialApp(
          theme: theme,
          locale: const Locale('ja'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            body: QuizQuestionView(
              key: const ValueKey('question'),
              team: team,
              question: QuizQuestion(
                id: 'question',
                sponsorId: 'sponsor',
                order: 1,
                title: const LocaleMap(ja: '問題', en: 'Question'),
                options: const [
                  LocaleMap(ja: '選択肢1', en: 'First'),
                  LocaleMap(ja: '選択肢2', en: 'Second'),
                  LocaleMap(ja: '選択肢3', en: 'Third'),
                  LocaleMap(ja: '選択肢4', en: 'Fourth'),
                ],
                status: status,
                closesAt: status == QuizQuestionStatus.reading ? null : serverNow.add(const Duration(seconds: 90)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> show(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  /// Contrast between an option label and its card, as composited over the page with any opacity applied.
  double labelContrast(WidgetTester tester, String label) {
    final text = find.text(label);
    final foreground = tester.renderObject<RenderParagraph>(text).text.style!.color!;
    var opacity = 1.0;
    Color? background;
    for (RenderObject? node = tester.renderObject(text); node != null; node = node.parent) {
      if (node is RenderOpacity) {
        opacity *= node.opacity;
      } else if (node is RenderAnimatedOpacity) {
        opacity *= node.opacity.value;
      } else if (node case RenderDecoratedBox(decoration: BoxDecoration(:final color?)) when background == null) {
        background = color;
      }
    }
    if (background == null) {
      fail('No card background found behind "$label".');
    }
    final page = Theme.of(tester.element(text)).colorScheme.surface;
    final a = Color.lerp(page, foreground, opacity)!.computeLuminance();
    final b = Color.lerp(page, background, opacity)!.computeLuminance();
    return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
  }

  testWidgets('reading shows question and options without a countdown or accepting answers', (tester) async {
    await show(tester, subject(status: QuizQuestionStatus.reading));
    expect(find.text('問題'), findsOneWidget);
    for (final number in ['1', '2', '3', '4']) {
      expect(find.text(number), findsOneWidget);
    }
    for (final letter in ['A', 'B', 'C', 'D']) {
      expect(find.text(letter), findsNothing);
    }
    expect(find.text(t.quiz.question.reading), findsOneWidget);
    expect(find.byIcon(Icons.timer_outlined), findsNothing);
    expect(find.text(t.quiz.question.tapHint), findsNothing);
    expect(tester.widgetList<QuizOptionCard>(find.byType(QuizOptionCard)).every((card) => !card.enabled), isTrue);
    await tester.tap(find.text('選択肢1'));
    expect(repository.calls, isEmpty);
  });

  for (final dark in [false, true]) {
    testWidgets('options stay readable while the question is being read (dark: $dark)', (tester) async {
      await show(tester, subject(status: QuizQuestionStatus.reading, theme: dark ? darkTheme() : lightTheme()));
      for (final label in ['選択肢1', '選択肢2', '選択肢3', '選択肢4']) {
        expect(labelContrast(tester, label), greaterThanOrEqualTo(4.5), reason: label);
      }
    });
  }

  testWidgets('countdown and input use server time even when device date differs by years', (tester) async {
    await show(tester, subject());
    expect(find.text('90'), findsOneWidget);
    expect(tester.widget<QuizOptionCard>(find.byType(QuizOptionCard).first).enabled, isTrue);
    // Move just beyond the deadline without expiring the calibration sample.
    clock.anchor = serverNow.add(const Duration(seconds: 89));
    clock.elapsed = const Duration(seconds: 2);
    ProviderScope.containerOf(tester.element(find.byType(QuizQuestionView))).invalidate(quizClockProvider);
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
    expect(tester.widget<QuizOptionCard>(find.byType(QuizOptionCard).first).enabled, isFalse);
    expect(find.text(t.quiz.question.locked), findsOneWidget);
  });

  testWidgets('an open question shows its number and invites a tap until the team answers', (tester) async {
    await show(tester, subject());
    expect(find.text(t.quiz.team.badge(name: 'Team')), findsOneWidget);
    expect(find.text(t.quiz.question.number(n: 1)), findsOneWidget);
    expect(find.text(t.quiz.question.tapHint), findsOneWidget);
    expect(find.text(t.quiz.question.accepted), findsNothing);
  });

  testWidgets("the team's server-confirmed answer is shown as accepted with who chose it", (tester) async {
    await show(tester, subject(answer: unanswered.copyWith(selectedOptionIndex: 2, answeredBy: 'hanako')));
    expect(tester.widget<QuizOptionCard>(find.byType(QuizOptionCard).at(2)).state, QuizOptionState.selected);
    expect(find.text(t.quiz.question.answeredBy(name: 'はなこ')), findsOneWidget);
    expect(find.text(t.quiz.question.accepted), findsOneWidget);
    expect(find.text(t.quiz.question.changeHint), findsOneWidget);
    expect(find.text(t.quiz.question.tapHint), findsNothing);
  });

  testWidgets('pending submission remains unselected until server receipt and cannot be double-sent', (tester) async {
    repository.pending = Completer<void>();
    await show(tester, subject());
    await tester.tap(find.text('選択肢1'));
    await tester.pump();
    expect(find.text(t.quiz.question.sending), findsOneWidget);
    expect(find.text(t.quiz.question.accepted), findsNothing);
    expect(find.text(t.quiz.question.tapHint), findsNothing);
    expect(
      tester
          .widgetList<QuizOptionCard>(find.byType(QuizOptionCard))
          .every((card) => card.state == QuizOptionState.idle),
      isTrue,
    );
    await tester.tap(find.text('選択肢2'));
    expect(repository.calls, [0]);
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.question.sending), findsNothing);
    expect(find.text(t.quiz.question.accepted), findsOneWidget);
  });

  testWidgets('offline failure does not claim that the answer was received', (tester) async {
    repository.failure = FirebaseFunctionsException(code: 'unavailable', message: 'offline');
    await show(tester, subject());
    await tester.tap(find.text('選択肢1'));
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.question.submitUnconfirmed), findsOneWidget);
    expect(find.text(t.quiz.question.accepted), findsNothing);
    expect(
      tester
          .widgetList<QuizOptionCard>(find.byType(QuizOptionCard))
          .every((card) => card.state == QuizOptionState.idle),
      isTrue,
    );
  });

  testWidgets('a timed-out submission becomes accepted once the server reports a newer team answer', (tester) async {
    final answers = StreamController<QuizAnswer?>()..add(unanswered);
    addTearDown(answers.close);
    final received = unanswered.copyWith(selectedOptionIndex: 1, answeredBy: 'hanako', submittedAt: serverNow);
    repository.failure = FirebaseFunctionsException(code: 'deadline-exceeded', message: 'timeout');
    await show(tester, subject(answers: answers.stream));
    await tester.tap(find.text('選択肢2'));
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.question.submitUnconfirmed), findsOneWidget);
    // A cached answer alone is not a server receipt.
    answers.add(received.copyWith(isFromCache: true));
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.question.submitUnconfirmed), findsOneWidget);
    expect(find.text(t.quiz.question.accepted), findsNothing);
    answers.add(received);
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.question.submitUnconfirmed), findsNothing);
    expect(find.text(t.quiz.question.accepted), findsOneWidget);
    expect(tester.widget<QuizOptionCard>(find.byType(QuizOptionCard).at(1)).state, QuizOptionState.selected);
  });

  testWidgets('a team answer confirmed while a submission times out is shown as accepted', (tester) async {
    final answers = StreamController<QuizAnswer?>()..add(unanswered);
    addTearDown(answers.close);
    repository.pending = Completer<void>();
    await show(tester, subject(answers: answers.stream));
    await tester.tap(find.text('選択肢2'));
    await tester.pump();
    // A teammate's answer is accepted by the server while this submission is still waiting.
    answers.add(unanswered.copyWith(selectedOptionIndex: 3, answeredBy: 'hanako', submittedAt: serverNow));
    await tester.pump();
    repository.pending!.completeError(FirebaseFunctionsException(code: 'deadline-exceeded', message: 'timeout'));
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.question.submitUnconfirmed), findsNothing);
    expect(find.text(t.quiz.question.accepted), findsOneWidget);
    expect(tester.widget<QuizOptionCard>(find.byType(QuizOptionCard).at(3)).state, QuizOptionState.selected);
  });

  testWidgets('cached answer is labeled and not displayed as a confirmed current selection', (tester) async {
    await show(tester, subject(answer: unanswered.copyWith(selectedOptionIndex: 1, isFromCache: true)));
    expect(find.text(t.quiz.question.cached), findsOneWidget);
    expect(find.text(t.quiz.question.accepted), findsNothing);
    expect(
      tester
          .widgetList<QuizOptionCard>(find.byType(QuizOptionCard))
          .every((card) => !card.enabled && card.state == QuizOptionState.idle),
      isTrue,
    );
  });

  testWidgets('an answer with unconfirmed local writes is not shown as accepted', (tester) async {
    await show(tester, subject(answer: unanswered.copyWith(selectedOptionIndex: 1, hasPendingWrites: true)));
    expect(find.text(t.quiz.question.cached), findsOneWidget);
    expect(find.text(t.quiz.question.accepted), findsNothing);
    expect(
      tester
          .widgetList<QuizOptionCard>(find.byType(QuizOptionCard))
          .every((card) => !card.enabled && card.state == QuizOptionState.idle),
      isTrue,
    );
  });

  testWidgets('clock synchronization failure disables answers and offers a retry', (tester) async {
    clock.failure = FirebaseFunctionsException(code: 'unavailable', message: 'offline');
    await show(tester, subject());
    expect(find.text(t.quiz.question.connectionUnavailable), findsOneWidget);
    expect(tester.widget<QuizOptionCard>(find.byType(QuizOptionCard).first).enabled, isFalse);
    clock.failure = null;
    await tester.tap(find.text(t.common.retry));
    await tester.pumpAndSettle();
    expect(tester.widget<QuizOptionCard>(find.byType(QuizOptionCard).first).enabled, isTrue);
  });

  testWidgets('moving away while submitting does not update a disposed widget', (tester) async {
    repository.pending = Completer<void>();
    await show(tester, subject());
    await tester.tap(find.text('選択肢1'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    repository.pending!.completeError(FirebaseFunctionsException(code: 'unavailable', message: 'offline'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _Answers extends Fake implements QuizAnswerRepository {
  final calls = <int>[];
  Completer<void>? pending;
  Exception? failure;

  @override
  Future<void> submit(
    String eventId,
    String questionId,
    String teamId, {
    required int selectedOptionIndex,
    String? uid,
  }) async {
    calls.add(selectedOptionIndex);
    if (failure case final error?) {
      throw error;
    }
    await pending?.future;
  }
}

class _Clock implements QuizClockRepository {
  _Clock(this.anchor);
  DateTime anchor;
  Duration elapsed = Duration.zero;
  Exception? failure;

  @override
  Future<QuizClock> synchronize() async {
    if (failure case final error?) {
      throw error;
    }
    // Capture a fixed anchor but allow test-controlled monotonic time advancement.
    final initialAnchor = anchor;
    return QuizClock(serverNow: initialAnchor, elapsed: () => anchor.difference(initialAnchor) + elapsed);
  }
}
