import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_repository.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_countdown.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_event_form_dialog.dart';
import 'package:dashboard/feature/quiz/ui/page/quiz_console_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final event = QuizEvent(
    id: 'event',
    title: const LocaleMap(ja: '午前の部', en: 'Morning'),
    status: QuizEventStatus.registration,
    isPublic: true,
    sponsorIds: const ['gold-a', 'deleted'],
    capacity: 40,
    teamNamePool: const ['旧チーム'],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  const question = QuizQuestion(
    id: 'question',
    sponsorId: 'gold-a',
    order: 1,
    title: LocaleMap(ja: '問題文', en: 'Question'),
    options: [
      LocaleMap(ja: '○', en: 'True'),
      LocaleMap(ja: '×', en: 'False'),
    ],
    status: QuizQuestionStatus.draft,
  );
  Sponsor sponsor(String id, String name, SponsorTier tier) => Sponsor(
    id: id,
    name: LocaleMap(ja: name, en: name),
    description: const LocaleMap(ja: '', en: ''),
    tier: tier,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  final sponsors = [
    sponsor('gold-b', 'B社', SponsorTier.gold),
    sponsor('gold-a', 'A社', SponsorTier.gold),
    sponsor('platinum', 'P社', SponsorTier.platinum),
  ];

  Future<_Events> showConsole(
    WidgetTester tester, {
    QuizEvent? eventValue,
    List<QuizQuestion>? questions,
    Stream<List<QuizQuestion>>? questionStream,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _Events();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: QuizConsolePage(eventId: 'event')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizClockRepositoryProvider.overrideWithValue(_Clock()),
          quizEventProvider('event').overrideWith((_) => Stream.value(eventValue ?? event)),
          quizParticipantListProvider('event').overrideWith((_) => Stream.value([])),
          quizTeamListProvider('event').overrideWith((_) => Stream.value([])),
          quizQuestionListProvider(
            'event',
          ).overrideWith((_) => questionStream ?? Stream.value(questions ?? [question])),
          quizSponsorListProvider.overrideWith((_) => Stream.value(sponsors)),
          quizAnswersByQuestionProvider.overrideWith((_, _) => Stream.value([])),
          quizOperationsRepositoryProvider.overrideWithValue(_Operations()),
          quizCheckInCodeProvider('event').overrideWith((_) => Stream.value(null)),
          quizEventRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // 問題を読み込み中のままにする場合はスピナーが回り続けるため settle しない。
    if (questionStream == null) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return repository;
  }

  Finder chip(String label) => find.widgetWithText(FilterChip, label);

  testWidgets('renames the event and changes sponsors while keeping capacity', (tester) async {
    final repository = await showConsole(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'イベントを編集'));
    await tester.pumpAndSettle();

    expect(find.text('クイズイベント編集'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '定員（人）*'), findsNothing);
    expect(find.text('選択中 2 社'), findsOneWidget);
    expect(find.text('見つからないスポンサー（1 社）'), findsOneWidget);
    // 問題で使っているスポンサーは外せない。
    expect(tester.widget<FilterChip>(chip('A社')).selected, isTrue);
    expect(tester.widget<FilterChip>(chip('A社')).onSelected, isNull);

    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル（日本語）*'), '午後の部');
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル（英語）*'), 'Afternoon');
    await tester.tap(chip('B社'));
    await tester.tap(chip('P社'));
    await tester.tap(chip('deleted'));
    await tester.pump();
    expect(find.text('見つからないスポンサー（1 社）'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final saved = repository.saved.single;
    expect(saved.id, 'event');
    expect(saved.title, const LocaleMap(ja: '午後の部', en: 'Afternoon'));
    expect(saved.sponsorIds, ['platinum', 'gold-a', 'gold-b']);
    expect(saved.capacity, 40);
    expect(saved.teamNamePool, ['旧チーム']);
    expect(saved.status, QuizEventStatus.registration);
    expect(find.text('クイズイベント編集'), findsNothing);
    expect(find.text('イベントを更新しました'), findsOneWidget);
  });

  testWidgets('clearing a plan keeps sponsors used by questions', (tester) async {
    final repository = await showConsole(tester, eventValue: event.copyWith(sponsorIds: ['gold-a', 'gold-b']));
    await tester.tap(find.widgetWithText(OutlinedButton, 'イベントを編集'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '解除'));
    await tester.pump();
    expect(tester.widget<FilterChip>(chip('A社')).selected, isTrue);
    expect(tester.widget<FilterChip>(chip('B社')).selected, isFalse);

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
    expect(repository.saved.single.sponsorIds, ['gold-a']);
  });

  testWidgets('a plan made only of locked sponsors cannot be cleared', (tester) async {
    await showConsole(
      tester,
      eventValue: event.copyWith(sponsorIds: ['gold-a', 'platinum']),
      questions: [
        question,
        question.copyWith(id: 'second', sponsorId: 'platinum'),
      ],
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'イベントを編集'));
    await tester.pumpAndSettle();
    // プラチナは使用中の P 社だけなので、外せるスポンサーがなく「解除」を押せない。
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, '解除')).onPressed, isNull);
    expect(tester.widget<FilterChip>(chip('P社')).onSelected, isNull);
  });

  testWidgets('the edit button waits until questions are loaded', (tester) async {
    await showConsole(tester, questionStream: const Stream.empty());
    final button = find.widgetWithText(OutlinedButton, 'イベントを編集');
    expect(button, findsOneWidget);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
  });

  for (final status in [QuizEventStatus.inProgress, QuizEventStatus.finished]) {
    testWidgets('the event cannot be edited once it is $status', (tester) async {
      await showConsole(tester, eventValue: event.copyWith(status: status));
      expect(find.text('イベントを編集'), findsNothing);
    });
  }

  testWidgets('creating an event still asks for capacity', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _Events();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizSponsorListProvider.overrideWith((_) => Stream.value(sponsors)),
          quizEventRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) => TextButton(
                      onPressed: () => QuizEventFormDialog.show(context: context, ref: ref),
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('クイズイベント新規作成'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル（日本語）*'), '新しい回');
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル（英語）*'), 'New');
    await tester.enterText(find.widgetWithText(TextFormField, '定員（人）*'), '30');
    await tester.tap(chip('A社'));
    await tester.tap(find.widgetWithText(FilledButton, '作成'));
    await tester.pumpAndSettle();

    final saved = repository.saved.single;
    expect(saved.isNew, isTrue);
    expect(saved.title, const LocaleMap(ja: '新しい回', en: 'New'));
    expect(saved.capacity, 30);
    expect(saved.sponsorIds, ['gold-a']);
    expect(saved.status, QuizEventStatus.draft);
  });
}

class _Events extends Fake implements QuizEventRepository {
  final saved = <QuizEvent>[];

  @override
  Future<String> save(QuizEvent event) async {
    saved.add(event);
    return event.isNew ? 'created' : event.id;
  }
}

class _Operations extends Fake implements QuizOperationsRepository {}

class _Clock implements QuizClockRepository {
  @override
  Future<QuizClock> synchronize() async => QuizClock(serverNow: DateTime(2026), elapsed: () => Duration.zero);
}
