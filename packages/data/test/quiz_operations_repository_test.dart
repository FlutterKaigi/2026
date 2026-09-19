import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('operations use authenticated server callable without writing lifecycle locally', () async {
    final firestore = FakeFirebaseFirestore();
    final functions = _Functions();
    final repository = FirestoreQuizOperationsRepository(firestore: firestore, functions: functions);
    await repository.presentQuestion('event', 'question');
    await repository.openQuestion('event', 'question');
    await repository.removeParticipant('event', 'attendee');
    expect(functions.calls.map((call) => {...call}..remove('operationId')).toList(), [
      {'eventId': 'event', 'operation': 'presentQuestion', 'questionId': 'question'},
      {'eventId': 'event', 'operation': 'openQuestion', 'questionId': 'question'},
      {'eventId': 'event', 'operation': 'removeParticipant', 'uid': 'attendee'},
    ]);
    expect(functions.calls.every((call) => (call['operationId'] as String).isNotEmpty), isTrue);
    expect((await firestore.collection('quizEvents').get()).docs, isEmpty);
  });

  test('extension retry reuses receipt after timeout but next confirmed operation gets a new receipt', () async {
    final functions = _Functions()
      ..error = FirebaseFunctionsException(code: 'deadline-exceeded', message: 'Test failure');
    final repository = FirestoreQuizOperationsRepository(firestore: FakeFirebaseFirestore(), functions: functions);
    await expectLater(
      repository.extendQuestion('event', 'question', seconds: 30),
      throwsA(isA<FirebaseFunctionsException>()),
    );
    functions.error = null;
    await repository.extendQuestion('event', 'question', seconds: 30);
    await repository.extendQuestion('event', 'question', seconds: 30);
    expect(functions.calls[0]['operationId'], functions.calls[1]['operationId']);
    expect(functions.calls[2]['operationId'], isNot(functions.calls[1]['operationId']));
    expect(functions.calls[0]['seconds'], 30);
  });

  test('rebuild retry reuses receipt after unavailable error', () async {
    final functions = _Functions()..error = FirebaseFunctionsException(code: 'unavailable', message: 'Test failure');
    final repository = FirestoreQuizOperationsRepository(firestore: FakeFirebaseFirestore(), functions: functions);
    await expectLater(repository.rebuildTeams('event'), throwsA(isA<FirebaseFunctionsException>()));
    functions.error = null;
    await repository.rebuildTeams('event');
    expect(functions.calls[0]['operationId'], functions.calls[1]['operationId']);
  });

  test('closing retry keeps its receipt across intervening extension, new close gets a new receipt', () async {
    final functions = _Functions()..error = FirebaseFunctionsException(code: 'unavailable', message: 'Test failure');
    final repository = FirestoreQuizOperationsRepository(firestore: FakeFirebaseFirestore(), functions: functions);
    await expectLater(repository.closeQuestion('event', 'question'), throwsA(isA<FirebaseFunctionsException>()));
    functions.error = null;
    await repository.extendQuestion('event', 'question', seconds: 30);
    await repository.closeQuestion('event', 'question');
    await repository.closeQuestion('event', 'question');
    expect(functions.calls[0]['operationId'], functions.calls[2]['operationId']);
    expect(functions.calls[0]['operationId'], isNot(functions.calls[3]['operationId']));
  });

  test('entry code retry preserves receipt and returns the saved code', () async {
    final functions = _Functions()
      ..error = FirebaseFunctionsException(code: 'deadline-exceeded', message: 'Test failure');
    final repository = FirestoreQuizOperationsRepository(firestore: FakeFirebaseFirestore(), functions: functions);
    await expectLater(repository.regenerateEntryCode('event'), throwsA(isA<FirebaseFunctionsException>()));
    functions.error = null;
    functions.result = {'code': '123456'};
    expect(await repository.regenerateEntryCode('event'), '123456');
    expect(functions.calls[0]['operationId'], functions.calls[1]['operationId']);
    functions.result = {'code': '654321'};
    expect(await repository.regenerateEntryCode('event'), '654321');
    expect(functions.calls[1]['operationId'], isNot(functions.calls[2]['operationId']));
  });

  test('definitive rejection starts the next attempt with a new receipt', () async {
    final functions = _Functions()
      ..error = FirebaseFunctionsException(code: 'failed-precondition', message: 'Test failure');
    final repository = FirestoreQuizOperationsRepository(firestore: FakeFirebaseFirestore(), functions: functions);
    await expectLater(repository.closeRegistration('event'), throwsA(isA<FirebaseFunctionsException>()));
    functions.error = null;
    await repository.closeRegistration('event');
    expect(functions.calls[0]['operationId'], isNot(functions.calls[1]['operationId']));
  });
}

class _Functions extends Fake implements FirebaseFunctions {
  FirebaseFunctionsException? error;
  Map<String, dynamic> result = {'ok': true};
  final calls = <Map<String, dynamic>>[];

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    expect(name, 'quizEventOperation');
    return _Callable((parameters) async {
      calls.add(Map<String, dynamic>.from(parameters as Map));
      if (error != null) throw error!;
      return result;
    });
  }
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
