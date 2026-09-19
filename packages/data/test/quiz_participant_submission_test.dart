import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registration sends only enrollment fields and cannot queue a local registration', () async {
    final firestore = FakeFirebaseFirestore();
    final pending = Completer<Object?>();
    final functions = _Functions((_) => pending.future);
    final repository = FirestoreQuizParticipantRepository(firestore: firestore, functions: functions);
    var completed = false;
    final registration = repository
        .register(
          'event',
          displayName: 'Alice',
          entryCode: '123456',
          uid: 'untrusted-client-uid',
          email: 'untrusted@example.com',
          signInProvider: 'untrusted-provider',
        )
        .then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    expect(functions.calls.single.$1, 'registerQuizParticipant');
    expect(functions.calls.single.$2, {'eventId': 'event', 'displayName': 'Alice', 'entryCode': '123456'});
    expect((await firestore.collection('quizEvents/event/participants').get()).docs, isEmpty);
    expect((await firestore.collection('quizEvents/event/entryClaims').get()).docs, isEmpty);
    pending.complete(null);
    await registration;
    expect(completed, isTrue);
  });

  test('answer waits for server acceptance and never changes the cached answer optimistically', () async {
    final firestore = FakeFirebaseFirestore();
    final pending = Completer<Object?>();
    final functions = _Functions((_) => pending.future);
    final repository = FirestoreQuizAnswerRepository(firestore: firestore, functions: functions);
    final answer = firestore.doc('quizEvents/event/answers/question_team');
    await answer.set({'questionId': 'question', 'teamId': 'team', 'selectedOptionIndex': 0});
    final submission = repository.submit('event', 'question', 'team', selectedOptionIndex: 1, uid: 'forged');
    await Future<void>.delayed(Duration.zero);
    expect((await answer.get()).data()?['selectedOptionIndex'], 0);
    expect(functions.calls.single.$1, 'submitQuizAnswer');
    expect(functions.calls.single.$2, {
      'eventId': 'event',
      'questionId': 'question',
      'teamId': 'team',
      'selectedOptionIndex': 1,
    });
    final failure = FirebaseFunctionsException(code: 'unavailable', message: 'offline');
    final expectation = expectLater(submission, throwsA(same(failure)));
    pending.completeError(failure);
    await expectation;
    expect((await answer.get()).data()?['selectedOptionIndex'], 0);
  });

  for (final code in [
    'resource-exhausted',
    'permission-denied',
    'already-exists',
    'failed-precondition',
    'unavailable',
  ]) {
    test('registration preserves $code for the UI', () async {
      final failure = FirebaseFunctionsException(code: code, message: code);
      final repository = FirestoreQuizParticipantRepository(
        firestore: FakeFirebaseFirestore(),
        functions: _Functions((_) => Future.error(failure)),
      );
      await expectLater(
        repository.register('event', displayName: 'Alice', entryCode: '123456'),
        throwsA(same(failure)),
      );
    });
  }

  test('quiz clock advances by monotonic elapsed time and expires after one minute', () {
    var elapsed = Duration.zero;
    final anchor = DateTime.utc(2020);
    final clock = QuizClock(serverNow: anchor, elapsed: () => elapsed);
    expect(clock.now, anchor);
    elapsed = const Duration(seconds: 19);
    expect(clock.now, anchor.add(elapsed));
    expect(clock.isFresh, isTrue);
    elapsed = const Duration(minutes: 1);
    expect(clock.isFresh, isFalse);
  });

  test('server clock synchronization uses the callable timestamp instead of the device date', () async {
    final serverDate = DateTime.utc(2020);
    final functions = _Functions((_) async => {'serverNowMs': serverDate.millisecondsSinceEpoch});
    final clock = await FirebaseQuizClockRepository(functions: functions).synchronize();
    expect(functions.calls.single.$1, 'getQuizServerTime');
    expect(clock.now.difference(serverDate).inSeconds, inInclusiveRange(0, 1));
  });
}

class _Functions extends Fake implements FirebaseFunctions {
  _Functions(this.invoke);

  final Future<Object?> Function(Object? parameters) invoke;
  final calls = <(String, Object?)>[];

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) => _Callable((parameters) {
    calls.add((name, parameters));
    return invoke(parameters);
  });
}

class _Callable extends Fake implements HttpsCallable {
  _Callable(this.invoke);
  final Future<Object?> Function(Object?) invoke;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async => _Result<T>(await invoke(parameters) as T);
}

class _Result<T> extends Fake implements HttpsCallableResult<T> {
  _Result(this.data);
  @override
  final T data;
}
