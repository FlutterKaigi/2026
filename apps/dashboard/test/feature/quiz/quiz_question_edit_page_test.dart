import 'dart:async';

import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_repository.dart';
import 'package:dashboard/feature/quiz/ui/page/quiz_question_edit_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final event = QuizEvent(
    id: 'event',
    title: const LocaleMap(ja: 'Quiz', en: 'Quiz'),
    status: QuizEventStatus.entryClosed,
    sponsorIds: const ['sponsor'],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  const question = QuizQuestion(
    id: 'question',
    sponsorId: 'sponsor',
    order: 1,
    title: LocaleMap(ja: '問題文', en: 'Question'),
    options: [
      LocaleMap(ja: '○', en: 'True'),
      LocaleMap(ja: '×', en: 'False'),
    ],
    durationSeconds: 180,
    status: QuizQuestionStatus.draft,
  );
  const secret = QuizQuestionSecret(
    correctOptionIndex: 1,
    explanation: LocaleMap(ja: '既存の解説', en: 'Existing explanation'),
  );

  testWidgets('duration-only edit loads and preserves private answer and explanation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _Questions();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Saved')),
        ),
        GoRoute(
          path: '/edit',
          builder: (_, _) => const Scaffold(
            body: QuizQuestionEditPage(eventId: 'event', questionId: 'question'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizEventProvider('event').overrideWith((_) => Stream.value(event)),
          quizSponsorListProvider.overrideWith((_) => Stream.value([])),
          quizQuestionProvider((eventId: 'event', questionId: 'question')).overrideWith((_) => Stream.value(question)),
          quizQuestionSecretProvider((
            eventId: 'event',
            questionId: 'question',
          )).overrideWith((_) => Stream.value(secret)),
          quizQuestionRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    unawaited(router.push<void>('/edit'));
    await tester.pumpAndSettle();
    expect(find.text('既存の解説'), findsOneWidget);
    final duration = find.widgetWithText(TextFormField, '制限時間（秒）*');
    await tester.ensureVisible(duration);
    await tester.enterText(duration, '90');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repository.savedQuestion?.durationSeconds, 90);
    expect(repository.savedSecret, secret);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('waits for private answer before exposing an editable form', (tester) async {
    final secretStream = StreamController<QuizQuestionSecret?>();
    addTearDown(secretStream.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizEventProvider('event').overrideWith((_) => Stream.value(event)),
          quizSponsorListProvider.overrideWith((_) => Stream.value([])),
          quizQuestionProvider((eventId: 'event', questionId: 'question')).overrideWith((_) => Stream.value(question)),
          quizQuestionSecretProvider((
            eventId: 'event',
            questionId: 'question',
          )).overrideWith((_) => secretStream.stream),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: QuizQuestionEditPage(eventId: 'event', question: question),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('保存'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    secretStream.addError(StateError('permission denied'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('読み込みに失敗しました'), findsOneWidget);
    expect(find.text('保存'), findsNothing);
  });
}

class _Questions extends Fake implements QuizQuestionRepository {
  QuizQuestion? savedQuestion;
  QuizQuestionSecret? savedSecret;

  @override
  Future<void> save(String eventId, QuizQuestion question, QuizQuestionSecret secret) async {
    savedQuestion = question;
    savedSecret = secret;
  }
}
