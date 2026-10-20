import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/page/quiz_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  final event = QuizEvent(
    id: 'event',
    title: const LocaleMap(ja: 'Quiz', en: 'Quiz'),
    status: QuizEventStatus.inProgress,
    currentQuestionId: 'question',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final participant = QuizParticipant(
    id: 'me',
    displayName: 'Alice',
    registeredAt: DateTime.utc(2026),
    checkedInAt: DateTime.utc(2026),
    teamId: 'C',
  );
  const team = QuizTeam(
    id: 'C',
    tableNumber: 3,
    name: 'C',
    score: 30,
    members: [
      QuizTeamMember(uid: 'me', displayName: 'Alice'),
      QuizTeamMember(uid: 'other', displayName: 'Bob'),
    ],
  );
  const revealed = QuizQuestion(
    id: 'question',
    sponsorId: 'sponsor',
    order: 3,
    title: LocaleMap(ja: '問題', en: 'Question'),
    options: [
      LocaleMap(ja: '選択肢1', en: 'First'),
      LocaleMap(ja: '選択肢2', en: 'Second'),
      LocaleMap(ja: '選択肢3', en: 'Third'),
      LocaleMap(ja: '選択肢4', en: 'Fourth'),
    ],
    status: QuizQuestionStatus.revealed,
    correctOptionIndex: 2,
  );

  QuizAnswer answered({required int selected, required bool isCorrect}) => QuizAnswer(
    id: 'question_C',
    questionId: 'question',
    teamId: 'C',
    selectedOptionIndex: selected,
    isCorrect: isCorrect,
  );

  Future<void> show(
    WidgetTester tester, {
    QuizQuestion? question,
    QuizAnswer? answer,
    Stream<QuizEvent>? events,
    Stream<QuizTeam?>? teams,
    Stream<QuizQuestion?>? questions,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          retry: (_, _) => null,
          overrides: [
            quizUserProvider.overrideWithValue(AsyncData(FakeUser(uid: 'me'))),
            quizEventProvider.overrideWith((_) => events ?? Stream.value(event)),
            myParticipantProvider.overrideWith((_) => Stream.value(participant)),
            quizParticipantsProvider.overrideWith((_) => Stream.value([participant])),
            myTeamProvider.overrideWith((_) => teams ?? Stream.value(team)),
            currentQuestionProvider.overrideWith((_) => questions ?? Stream.value(question)),
            teamAnswerProvider.overrideWith((_) => Stream.value(answer)),
            quizSponsorsProvider.overrideWith((_) => Stream.value(<Sponsor>[])),
            quizClockRepositoryProvider.overrideWithValue(_Clock()),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const QuizPage(eventId: 'event'),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
      return;
    }
    // The loading indicator never settles, so deliver the streams frame by frame.
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('team announcement names the team once and shows the rules', (tester) async {
    await show(tester);
    expect(find.text(t.quiz.team.yourTable), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text(t.quiz.rules.title), findsOneWidget);
    expect(find.text(t.quiz.team.gatherHint), findsOneWidget);
  });

  testWidgets('the rules are shown after team selection closes until the first question starts', (tester) async {
    final events = StreamController<QuizEvent>()
      ..add(
        event.copyWith(
          status: QuizEventStatus.entryClosed,
          teamSelectionStatus: QuizTeamSelectionStatus.closed,
          currentQuestionId: null,
        ),
      );
    final teams = StreamController<QuizTeam?>()..add(null);
    final questions = StreamController<QuizQuestion?>()..add(null);
    addTearDown(events.close);
    addTearDown(teams.close);
    addTearDown(questions.close);
    await show(tester, events: events.stream, teams: teams.stream, questions: questions.stream);
    expect(find.text(t.quiz.selection.closed), findsOneWidget);
    expect(find.text(t.quiz.rules.title), findsOneWidget);

    // The first question creates the teams and starts the event in one update.
    events.add(event.copyWith(teamSelectionStatus: QuizTeamSelectionStatus.closed));
    teams.add(team);
    questions.add(revealed.copyWith(status: QuizQuestionStatus.reading, correctOptionIndex: null));
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.question.reading), findsOneWidget);
    expect(find.text(t.quiz.rules.title), findsNothing);
  });

  testWidgets('a started round without its team yet shows loading, not the check-in guidance', (tester) async {
    final teams = StreamController<QuizTeam?>()..add(null);
    addTearDown(teams.close);
    await show(tester, teams: teams.stream, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(t.quiz.waiting.title), findsNothing);
    expect(find.text(t.quiz.waiting.description), findsNothing);

    teams.add(team);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(t.quiz.team.yourTable), findsOneWidget);
  });

  testWidgets('a correct answer leads with the points gained and the team total', (tester) async {
    await show(tester, question: revealed, answer: answered(selected: 2, isCorrect: true));
    expect(find.textContaining(t.quiz.question.number(n: '3')), findsOneWidget);
    expect(find.text(t.quiz.revealed.correct), findsOneWidget);
    expect(find.text(t.quiz.revealed.gain(points: '10')), findsOneWidget);
    expect(find.text(t.quiz.revealed.teamScore(score: '30')), findsOneWidget);
    expect(find.text(t.quiz.revealed.wrong), findsNothing);
  });

  testWidgets('a wrong answer shows the team total and marks the team answer without points gained', (tester) async {
    await show(tester, question: revealed, answer: answered(selected: 0, isCorrect: false));
    expect(find.text(t.quiz.revealed.wrong), findsOneWidget);
    expect(find.text(t.quiz.revealed.teamScore(score: '30')), findsOneWidget);
    expect(find.text(t.quiz.revealed.yourAnswer), findsOneWidget);
    expect(find.text(t.quiz.revealed.gain(points: '10')), findsNothing);
    expect(find.text(t.quiz.revealed.correct), findsNothing);
  });

  testWidgets('a team without an answer sees the reveal heading instead of a verdict', (tester) async {
    await show(tester, question: revealed);
    expect(find.text(t.quiz.revealed.title), findsOneWidget);
    expect(find.text(t.quiz.revealed.correct), findsNothing);
    expect(find.text(t.quiz.revealed.wrong), findsNothing);
    expect(find.text(t.quiz.revealed.gain(points: '10')), findsNothing);
  });

  testWidgets('a graded answer without a selection is not shown as wrong', (tester) async {
    // The server grades the answer created at open as isCorrect: false when the team never answers.
    await show(
      tester,
      question: revealed,
      answer: const QuizAnswer(id: 'question_C', questionId: 'question', teamId: 'C', isCorrect: false),
    );
    expect(find.text(t.quiz.revealed.title), findsOneWidget);
    expect(find.text(t.quiz.revealed.teamScore(score: '30')), findsOneWidget);
    expect(find.text(t.quiz.revealed.wrong), findsNothing);
    expect(find.text(t.quiz.revealed.correct), findsNothing);
    expect(find.text(t.quiz.revealed.yourAnswer), findsNothing);
  });
}

class _Clock implements QuizClockRepository {
  @override
  Future<QuizClock> synchronize() async => QuizClock(serverNow: DateTime.utc(2026), elapsed: () => Duration.zero);
}
