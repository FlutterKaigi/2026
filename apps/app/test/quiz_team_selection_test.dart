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
    ValueNotifier<QuizTeamSelectionStatus>? statuses,
    TextScaler? textScaler,
  }) async {
    final selection = statuses ?? ValueNotifier(status);
    if (statuses == null) {
      addTearDown(selection.dispose);
    }
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
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler ?? MediaQuery.textScalerOf(context)),
              child: child!,
            ),
            home: Scaffold(
              body: ListenableBuilder(
                listenable: Listenable.merge([current, selection]),
                builder: (_, _) => QuizTeamSelectionView(
                  event: event.copyWith(teamSelectionStatus: selection.value),
                  participant: current.value,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// チームのタイル（A〜T）の押し先。
  Iterable<InkWell> tiles(WidgetTester tester) =>
      tester.widgetList<InkWell>(find.descendant(of: find.byType(GridView), matching: find.byType(InkWell)));

  testWidgets('twenty alphabet choices send one request and wait for confirmed membership', (tester) async {
    final repository = _Participants()..pending = Completer<void>();
    final current = ValueNotifier(person);
    addTearDown(current.dispose);
    await show(tester, repository, current);
    expect(tiles(tester), hasLength(20));
    expect(find.text(t.quiz.progress.selectTeam), findsOneWidget);
    // 選択していないうちは決定できない。
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.tap(find.text(t.quiz.selection.confirm));
    await tester.pump();
    expect(repository.calls, [('A', null)]);
    expect(tiles(tester).every((tile) => tile.onTap == null), isTrue);
    expect(find.text(t.quiz.selection.sending), findsOneWidget);
    expect(find.text(t.quiz.selection.unselected), findsOneWidget);
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.selection.unselected), findsOneWidget);
    current.value = person.copyWith(teamId: 'A');
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.selection.current(team: 'A')), findsOneWidget);
    // 保存済みのチームを選び直しても送らない。
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.ensureVisible(find.text('T'));
    await tester.tap(find.text('T'));
    await tester.pump();
    await tester.tap(find.text(t.quiz.selection.confirm));
    await tester.pumpAndSettle();
    expect(repository.calls.last, ('T', 'A'));
  });

  testWidgets('team tiles are announced as buttons with their members and selection', (tester) async {
    final semantics = tester.ensureSemantics();
    final current = ValueNotifier(person.copyWith(teamId: 'B'));
    addTearDown(current.dispose);
    await show(tester, _Participants(), current);
    expect(
      tester.getSemantics(find.text('B')),
      isSemantics(
        label: t.quiz.selection.option(team: 'B', count: '1'),
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('C')),
      isSemantics(
        label: t.quiz.selection.option(team: 'C', count: '0'),
        isButton: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(tester.getSemantics(find.text('C')), isSemantics(isSelected: true));
    expect(tester.getSemantics(find.text('B')), isSemantics(isSelected: false));
    semantics.dispose();
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
    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.tap(find.text(t.quiz.selection.confirm));
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.selection.changed), findsOneWidget);
    expect(find.text(t.quiz.selection.current(team: 'A')), findsOneWidget);
    expect(repository.calls, [('B', 'A')]);
  });

  testWidgets('a failure after selection closes asks for no retry', (tester) async {
    final repository = _Participants()
      ..pending = Completer<void>()
      ..failure = FirebaseFunctionsException(code: 'unavailable', message: 'unavailable');
    final current = ValueNotifier(person);
    final statuses = ValueNotifier(QuizTeamSelectionStatus.open);
    addTearDown(current.dispose);
    addTearDown(statuses.dispose);
    await show(tester, repository, current, statuses: statuses);
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.tap(find.text(t.quiz.selection.confirm));
    await tester.pump();
    // 送信中に運営がチーム選択を締め切り、そのあとで失敗が届く。
    statuses.value = QuizTeamSelectionStatus.closed;
    await tester.pump();
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.selection.closedUnselected), findsOneWidget);
    expect(find.text(t.quiz.selection.failed), findsNothing);
    // 受付を再開しても、閉じている間に届いた失敗は残さない。
    statuses.value = QuizTeamSelectionStatus.open;
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.selection.confirm), findsOneWidget);
    expect(find.text(t.quiz.selection.failed), findsNothing);
  });

  testWidgets('closing selection clears a failure shown while it was open', (tester) async {
    final repository = _Participants()
      ..failure = FirebaseFunctionsException(code: 'unavailable', message: 'unavailable');
    final current = ValueNotifier(person);
    final statuses = ValueNotifier(QuizTeamSelectionStatus.open);
    addTearDown(current.dispose);
    addTearDown(statuses.dispose);
    await show(tester, repository, current, statuses: statuses);
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.tap(find.text(t.quiz.selection.confirm));
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.selection.failed), findsOneWidget);
    statuses.value = QuizTeamSelectionStatus.closed;
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.selection.failed), findsNothing);
  });

  testWidgets('team tiles fit their name and member count with nonlinear enlarged text', (tester) async {
    final current = ValueNotifier(person.copyWith(teamId: 'A'));
    addTearDown(current.dispose);
    await show(tester, _Participants(), current, textScaler: const _NonlinearTextScaler());
    final tile = tester.getRect(find.ancestor(of: find.text('A'), matching: find.byType(InkWell)));
    final count = tester.getRect(find.descendant(of: find.byType(GridView), matching: find.text('1')));
    expect(tile.top, lessThanOrEqualTo(tester.getRect(find.text('A')).top));
    expect(tile.bottom, greaterThanOrEqualTo(count.bottom));
    expect(tester.takeException(), isNull);
  });

  for (final teamId in <String?>[null, 'T']) {
    testWidgets('closed selection keeps membership and guides unselected attendees: $teamId', (tester) async {
      final current = ValueNotifier(person.copyWith(teamId: teamId));
      addTearDown(current.dispose);
      await show(tester, _Participants(), current, status: QuizTeamSelectionStatus.closed);
      expect(find.byType(GridView), findsNothing);
      expect(find.text(t.quiz.selection.confirm), findsNothing);
      expect(find.text(teamId == null ? t.quiz.selection.closedUnselected : t.quiz.selection.closed), findsOneWidget);
      expect(
        find.text(teamId == null ? t.quiz.selection.unselected : t.quiz.selection.current(team: teamId)),
        findsOneWidget,
      );
      // チームが決まっていれば、初出題を待つ間にルールを確認できる。
      expect(find.text(t.quiz.rules.title), teamId == null ? findsNothing : findsOneWidget);
    });
  }
}

/// Android の文字の大きさ 200% のように、大きな文字ほど倍率を下げて拡大する。
class _NonlinearTextScaler extends TextScaler {
  const _NonlinearTextScaler();

  /// 拡大前と拡大後の文字の大きさの対応。間は線形に補う。
  static const List<(double, double)> _table = [(8, 16), (12, 24), (20, 36), (24, 40), (30, 50), (100, 100)];

  @override
  double scale(double fontSize) {
    if (fontSize <= _table.first.$1) {
      return fontSize * 2;
    }
    for (var index = 1; index < _table.length; index++) {
      final (fromSize, fromScaled) = _table[index - 1];
      final (toSize, toScaled) = _table[index];
      if (fontSize <= toSize) {
        return fromScaled + (fontSize - fromSize) / (toSize - fromSize) * (toScaled - fromScaled);
      }
    }
    return fontSize;
  }

  @override
  double get textScaleFactor => 2;
}

class _Participants extends Fake implements QuizParticipantRepository {
  final calls = <(String, String?)>[];
  Completer<void>? pending;
  FirebaseFunctionsException? failure;

  @override
  Future<void> selectTeam(String eventId, String teamId, {required String? expectedTeamId}) async {
    calls.add((teamId, expectedTeamId));
    await pending?.future;
    if (failure case final error?) {
      throw error;
    }
  }
}
