import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/component/quiz_team_selection_view.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));
  final event = QuizEvent(
    id: 'event',
    title: const LocaleMap(ja: 'Quiz', en: 'Quiz'),
    status: QuizEventStatus.entryClosed,
    teamSelectionStatus: QuizTeamSelectionStatus.open,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final person = QuizParticipant(id: 'member', displayName: 'Member', registeredAt: DateTime.utc(2026));

  Future<void> show(
    WidgetTester tester,
    _Participants repository,
    ValueNotifier<QuizParticipant> current, {
    QuizTeamSelectionStatus status = QuizTeamSelectionStatus.open,
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            quizParticipantRepositoryProvider.overrideWithValue(repository),
            quizParticipantsProvider.overrideWith((_) => Stream.value([current.value])),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(
              body: ValueListenableBuilder(
                valueListenable: current,
                builder: (_, participant, _) => QuizTeamSelectionView(
                  event: event.copyWith(teamSelectionStatus: status),
                  participant: participant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('twenty alphabet choices send one request and wait for confirmed membership', (tester) async {
    final repository = _Participants()..pending = Completer<void>();
    final current = ValueNotifier(person);
    addTearDown(current.dispose);
    await show(tester, repository, current);
    expect(find.byType(ChoiceChip), findsNWidgets(20));
    await tester.tap(find.text(t.quiz.selection.option(team: 'A', count: '0')));
    await tester.pump();
    await tester.ensureVisible(find.text(t.quiz.selection.confirm));
    await tester.tap(find.text(t.quiz.selection.confirm));
    await tester.pump();
    expect(repository.calls, [('A', null)]);
    expect(tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).every((chip) => chip.onSelected == null), isTrue);
    expect(find.text(t.quiz.selection.unselected), findsOneWidget);
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.selection.unselected), findsOneWidget);
    current.value = person.copyWith(teamId: 'A');
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.selection.current(team: 'A')), findsOneWidget);
    await tester.ensureVisible(find.text(t.quiz.selection.option(team: 'T', count: '0')));
    await tester.tap(find.text(t.quiz.selection.option(team: 'T', count: '0')));
    await tester.pump();
    await tester.ensureVisible(find.text(t.quiz.selection.confirm));
    await tester.tap(find.text(t.quiz.selection.confirm));
    await tester.pumpAndSettle();
    expect(repository.calls.last, ('T', 'A'));
  });

  testWidgets('rejected changes keep the confirmed team and show a useful error', (tester) async {
    final repository = _Participants()
      ..failure = FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'Membership changed',
        details: const {'reason': 'team-changed'},
      );
    final current = ValueNotifier(person.copyWith(teamId: 'A'));
    addTearDown(current.dispose);
    await show(tester, repository, current);
    await tester.tap(find.text(t.quiz.selection.option(team: 'B', count: '0')));
    await tester.pump();
    await tester.ensureVisible(find.text(t.quiz.selection.confirm));
    await tester.tap(find.text(t.quiz.selection.confirm));
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.selection.changed), findsOneWidget);
    expect(find.text(t.quiz.selection.current(team: 'A')), findsOneWidget);
    expect(repository.calls, [('B', 'A')]);
  });

  for (final teamId in <String?>[null, 'T']) {
    testWidgets('closed selection keeps membership and guides unselected attendees: $teamId', (tester) async {
      final current = ValueNotifier(person.copyWith(teamId: teamId));
      addTearDown(current.dispose);
      await show(tester, _Participants(), current, status: QuizTeamSelectionStatus.closed);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text(teamId == null ? t.quiz.selection.closedUnselected : t.quiz.selection.closed), findsOneWidget);
    });
  }
}

class _Participants extends Fake implements QuizParticipantRepository {
  final calls = <(String, String?)>[];
  Completer<void>? pending;
  FirebaseFunctionsException? failure;

  @override
  Future<void> selectTeam(String eventId, String teamId, {required String? expectedTeamId}) async {
    calls.add((teamId, expectedTeamId));
    if (failure case final error?) {
      throw error;
    }
    await pending?.future;
  }
}
