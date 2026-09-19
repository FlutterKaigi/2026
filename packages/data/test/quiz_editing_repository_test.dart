import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data/data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreQuizEventRepository events;
  late FirestoreQuizQuestionRepository questions;
  final now = DateTime.utc(2026, 9, 19);
  final staleEvent = QuizEvent(
    id: 'event',
    title: const LocaleMap(ja: 'Quiz', en: 'Quiz'),
    status: QuizEventStatus.draft,
    createdAt: now,
    updatedAt: now,
  );
  const draft = QuizQuestion(
    id: 'question',
    sponsorId: 'sponsor',
    order: 1,
    title: LocaleMap(ja: '問題', en: 'Question'),
    options: [
      LocaleMap(ja: '○', en: 'True'),
      LocaleMap(ja: '×', en: 'False'),
    ],
    durationSeconds: 180,
    status: QuizQuestionStatus.draft,
  );
  const secret = QuizQuestionSecret(
    correctOptionIndex: 1,
    explanation: LocaleMap(ja: '保存済みの解説', en: 'Saved explanation'),
  );

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    events = FirestoreQuizEventRepository(firestore: firestore);
    questions = FirestoreQuizQuestionRepository(firestore: firestore);
    await firestore.doc('quizEvents/event').set(staleEvent.toJson()..remove('id'));
    await firestore.doc('quizEvents/event/questions/question').set(draft.toJson()..remove('id'));
    await firestore.doc('quizEvents/event/questions/question/secret/answer').set(secret.toJson());
  });

  test('stale event settings never overwrite published lifecycle or server counters', () async {
    await firestore.doc('quizEvents/event').update({
      'status': 'registration',
      'isPublic': true,
      'participantCount': 40,
      'revision': 6,
    });
    await events.save(
      staleEvent.copyWith(
        title: const LocaleMap(ja: '新タイトル', en: 'New title'),
      ),
    );
    final saved = (await firestore.doc('quizEvents/event').get()).data()!;
    expect(saved['status'], 'registration');
    expect(saved['isPublic'], isTrue);
    expect(saved['participantCount'], 40);
    expect(saved['revision'], 6);
    expect(saved['title'], {'ja': '新タイトル', 'en': 'New title'});
  });

  test('event settings opened before start cannot be saved after start', () async {
    await firestore.doc('quizEvents/event').update({'status': 'inProgress', 'currentQuestionId': 'question'});
    await expectLater(events.save(staleEvent), throwsStateError);
    expect((await firestore.doc('quizEvents/event').get()).data()!['currentQuestionId'], 'question');
  });

  test('team name pool changes preserve live progress and other settings', () async {
    await firestore.doc('quizEvents/event').update({
      'status': 'inProgress',
      'currentQuestionId': 'question',
      'isPublic': true,
      'capacity': 40,
    });
    await events.updateTeamNamePool('event', ['Scaffold', 'Hero']);
    final saved = (await firestore.doc('quizEvents/event').get()).data()!;
    expect(saved['status'], 'inProgress');
    expect(saved['currentQuestionId'], 'question');
    expect(saved['capacity'], 40);
    expect(saved['teamNamePool'], ['Scaffold', 'Hero']);
  });

  test('rejects capacity exceeding venue capacity or already registered count', () async {
    await expectLater(events.save(staleEvent.copyWith(capacity: 81)), throwsArgumentError);
    await firestore.doc('quizEvents/event').update({'participantCount': 20});
    await expectLater(events.save(staleEvent.copyWith(capacity: 19)), throwsStateError);
  });

  test('capacity is fixed once registration opens even before anyone registers', () async {
    await firestore.doc('quizEvents/event').update({'status': 'registration'});
    await expectLater(events.save(staleEvent.copyWith(capacity: 40)), throwsStateError);
    expect((await firestore.doc('quizEvents/event').get()).get('capacity'), 80);
  });

  test('prepared admission slots also freeze capacity before reception changes state', () async {
    await firestore.doc('quizEvents/event').update({'status': 'published', 'admissionSlotsReady': true});
    await expectLater(events.save(staleEvent.copyWith(capacity: 40)), throwsStateError);
  });

  for (final status in ['reading', 'open', 'closed', 'revealed']) {
    test('stale draft save and delete refuse question already $status', () async {
      final questionRef = firestore.doc('quizEvents/event/questions/question');
      final deadline = Timestamp.fromDate(now.add(const Duration(minutes: 3)));
      await questionRef.update({'status': status, 'closesAt': deadline});
      await expectLater(questions.save('event', draft, secret), throwsStateError);
      await expectLater(questions.delete('event', 'question'), throwsStateError);
      final saved = (await questionRef.get()).data()!;
      expect(saved['status'], status);
      expect(saved['closesAt'], deadline);
      expect((await firestore.doc('quizEvents/event/questions/question/secret/answer').get()).data(), secret.toJson());
    });
  }

  test('draft question cannot be changed after another question starts', () async {
    await firestore.doc('quizEvents/event').update({'status': 'inProgress'});
    await expectLater(questions.save('event', draft, secret), throwsStateError);
    await expectLater(questions.delete('event', 'question'), throwsStateError);
  });

  test('draft duration edit preserves secret loaded from its private document', () async {
    final storedSecret = await questions.watchSecret('event', 'question').first;
    expect(storedSecret, secret);
    await questions.save('event', draft.copyWith(durationSeconds: 90), storedSecret!);
    // fake_cloud_firestore's transaction starts document writes without awaiting them.
    // Observe their stream delivery instead of the fake's synchronous initial snapshot.
    final saved = await questions.watchById('event', 'question').firstWhere((q) => q?.durationSeconds == 90);
    expect(saved?.durationSeconds, 90);
    expect(saved?.correctOptionIndex, isNull);
    expect(saved?.explanation, isNull);
    expect(await questions.watchSecret('event', 'question').first, secret);
  });
}
