import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseSupportLtRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirebaseSupportLtRepository(firestore: firestore, functions: _StubFunctions());
  });

  group('watchRegistration', () {
    test('emits null when the attendee has not registered', () async {
      expect(await repository.watchRegistration('attendee-1').first, isNull);
    });

    test('uses the document ID as the UID and parses the server timestamp', () async {
      await firestore.collection('supportLtRegistrations').doc('attendee-1').set(_registrationData());

      final registration = await repository.watchRegistration('attendee-1').first;

      expect(registration?.uid, 'attendee-1');
      expect(registration?.displayName, '参加者');
      expect(registration?.registeredAt.isAtSameMomentAs(_registeredAt), isTrue);
    });

    test('reports a malformed timestamp instead of claiming registration succeeded', () async {
      await firestore.collection('supportLtRegistrations').doc('attendee-1').set({
        ..._registrationData(),
        'registeredAt': null,
      });

      await expectLater(repository.watchRegistration('attendee-1').first, throwsFormatException);
    });

    test('forwards subsequent server registration and deletion updates', () async {
      final document = firestore.collection('supportLtRegistrations').doc('attendee-1');
      final updates = StreamIterator(repository.watchRegistration('attendee-1'));
      addTearDown(updates.cancel);
      expect(await updates.moveNext(), isTrue);
      expect(updates.current, isNull);

      await document.set(_registrationData());
      expect(await updates.moveNext(), isTrue);
      expect(updates.current?.uid, 'attendee-1');

      await document.delete();
      expect(await updates.moveNext(), isTrue);
      expect(updates.current, isNull);
    });
  });

  group('watchRegistrations', () {
    test('emits an immutable empty list when no one has registered', () async {
      final registrations = await repository.watchRegistrations().first;

      expect(registrations, isEmpty);
      expect(() => registrations.clear(), throwsUnsupportedError);
    });

    test('lists registrations most recently registered first in an immutable list', () async {
      final registrations = firestore.collection('supportLtRegistrations');
      await registrations.doc('earlier').set(_registrationData());
      await registrations
          .doc('later')
          .set(
            _registrationData(displayName: '後の参加者', registeredAt: _registeredAt.add(const Duration(minutes: 1))),
          );

      final result = await repository.watchRegistrations().first;

      expect(result.map((registration) => registration.uid), ['later', 'earlier']);
      expect(result.first.displayName, '後の参加者');
      expect(() => result.removeLast(), throwsUnsupportedError);
    });

    test('reports malformed participant data without silently excluding the participant', () async {
      await firestore.collection('supportLtRegistrations').doc('attendee-1').set({
        ..._registrationData(),
        'displayName': 123,
      });

      await expectLater(repository.watchRegistrations().first, throwsFormatException);
    });
  });

  group('watchCode', () {
    test('emits null when no code has been issued', () async {
      expect(await repository.watchCode().first, isNull);
    });

    test('reads the current code and timestamp fields', () async {
      await firestore.collection('supportLtSettings').doc('current').set(_codeData());

      final code = await repository.watchCode().first;

      expect(code?.code, 'ABC123');
      expect(code?.issuedAt.isAtSameMomentAs(_issuedAt), isTrue);
    });

    test('reports an invalid timestamp', () async {
      await firestore.collection('supportLtSettings').doc('current').set({..._codeData(), 'issuedAt': 'invalid'});

      await expectLater(repository.watchCode().first, throwsFormatException);
    });
  });

  group('callable writes', () {
    test('issues a code with rotation disabled by default without a client-side write', () async {
      final functions = _StubFunctions(result: _codeResult());
      final repository = FirebaseSupportLtRepository(firestore: firestore, functions: functions);

      await repository.issueCode();

      expect(functions.calls.single.$1, 'issueSupportLtCode');
      expect(functions.calls.single.$2, {'rotate': false});
      expect((await firestore.collection('supportLtSettings').get()).docs, isEmpty);
    });

    test('requests rotation explicitly', () async {
      final functions = _StubFunctions(result: _codeResult());
      final repository = FirebaseSupportLtRepository(firestore: firestore, functions: functions);

      await repository.issueCode(rotate: true);

      expect(functions.calls.single.$1, 'issueSupportLtCode');
      expect(functions.calls.single.$2, {'rotate': true});
    });

    test('delegates registration to the authenticated callable without a client-side write', () async {
      final functions = _StubFunctions(
        result: {'registeredAt': _registeredAt.millisecondsSinceEpoch, 'alreadyRegistered': false},
      );
      final repository = FirebaseSupportLtRepository(firestore: firestore, functions: functions);

      await repository.register('ABC123');

      expect(functions.calls.single.$1, 'registerSupportLt');
      expect(functions.calls.single.$2, {'code': 'ABC123'});
      expect((await firestore.collection('supportLtRegistrations').get()).docs, isEmpty);
    });

    test('preserves registration error codes for the app', () async {
      final error = FirebaseFunctionsException(code: 'permission-denied', message: 'Incorrect code.');
      final repository = FirebaseSupportLtRepository(
        firestore: firestore,
        functions: _StubFunctions(error: error),
      );

      await expectLater(repository.register('WRONG1'), throwsA(same(error)));
    });

    test('preserves issuance errors for the dashboard', () async {
      final error = FirebaseFunctionsException(code: 'permission-denied', message: 'Staff access required.');
      final repository = FirebaseSupportLtRepository(
        firestore: firestore,
        functions: _StubFunctions(error: error),
      );

      await expectLater(repository.issueCode(), throwsA(same(error)));
    });
  });
}

final _issuedAt = DateTime.utc(2026, 9, 11, 1);
final _registeredAt = _issuedAt.add(const Duration(minutes: 1));

Map<String, dynamic> _registrationData({String displayName = '参加者', DateTime? registeredAt}) => {
  'displayName': displayName,
  'registeredAt': Timestamp.fromDate(registeredAt ?? _registeredAt),
  'codeVersion': 1,
};

Map<String, dynamic> _codeData() => {
  'code': 'ABC123',
  'issuedAt': Timestamp.fromDate(_issuedAt),
  'issuedBy': 'staff-1',
  'version': 1,
};

Map<String, dynamic> _codeResult() => {'code': 'ABC123', 'issuedAt': _issuedAt.millisecondsSinceEpoch};

class _StubFunctions extends Fake implements FirebaseFunctions {
  _StubFunctions({this.result, this.error});

  final Object? result;
  final Exception? error;
  List<(String, Object?)> calls = [];

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) => _StubCallable((parameters) async {
    calls = [...calls, (name, parameters)];
    if (error case final exception?) {
      throw exception;
    }
    return result;
  });
}

class _StubCallable extends Fake implements HttpsCallable {
  _StubCallable(this.invoke);

  final Future<Object?> Function(Object? parameters) invoke;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async =>
      _StubCallableResult<T>(await invoke(parameters) as T);
}

class _StubCallableResult<T> extends Fake implements HttpsCallableResult<T> {
  _StubCallableResult(this.data);

  @override
  final T data;
}
