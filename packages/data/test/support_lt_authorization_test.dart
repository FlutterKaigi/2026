import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StreamController<DocumentSnapshot<Map<String, dynamic>>> codes;
  late StreamController<QuerySnapshot<Map<String, dynamic>>> registrations;
  late DocumentSnapshot<Map<String, dynamic>> codeSnapshot;
  late QuerySnapshot<Map<String, dynamic>> registrationsSnapshot;
  late FirebaseSupportLtRepository repository;

  setUp(() async {
    codes = StreamController.broadcast();
    registrations = StreamController.broadcast();
    addTearDown(codes.close);
    addTearDown(registrations.close);
    final firestore = FakeFirebaseFirestore();
    final timestamp = Timestamp.fromDate(DateTime.utc(2026, 9, 11));
    final code = firestore.collection('supportLtSettings').doc('current');
    await code.set({'code': 'ABC123', 'issuedAt': timestamp});
    await firestore.collection('supportLtRegistrations').doc('attendee-1').set({
      'displayName': '参加者',
      'registeredAt': timestamp,
    });
    codeSnapshot = await code.get();
    registrationsSnapshot = await firestore.collection('supportLtRegistrations').get();
    repository = FirebaseSupportLtRepository(
      firestore: _SnapshotFirestore(codes.stream, registrations.stream),
      functions: _UnusedFunctions(),
    );
  });

  void emitCache() {
    codes.add(_SourcedDocument(codeSnapshot, isFromCache: true));
    registrations.add(_SourcedQuery(registrationsSnapshot, isFromCache: true));
  }

  void emitServer() {
    codes.add(_SourcedDocument(codeSnapshot, isFromCache: false));
    registrations.add(_SourcedQuery(registrationsSnapshot, isFromCache: false));
  }

  test(
    'withholds populated staff cache until the server confirms access, including metadata-only confirmation',
    () async {
      var codePublished = false;
      var registrationsPublished = false;
      final code = repository.watchCode().first.then((value) {
        codePublished = true;
        return value;
      });
      final participants = repository.watchRegistrations().first.then((value) {
        registrationsPublished = true;
        return value;
      });

      emitCache();
      await Future<void>.delayed(Duration.zero);

      expect(codePublished, isFalse);
      expect(registrationsPublished, isFalse);

      emitServer();
      expect((await code)?.code, 'ABC123');
      expect((await participants).single.uid, 'attendee-1');
    },
  );

  test('a new subscription cannot reuse earlier staff authorization when the next user is denied', () async {
    final earlierAccess = Future.wait<Object?>([
      repository.watchCode().first,
      repository.watchRegistrations().first,
    ]);
    emitServer();
    await earlierAccess;
    final denied = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    final expectations = Future.wait([
      expectLater(repository.watchCode(), emitsError(same(denied))),
      expectLater(repository.watchRegistrations(), emitsError(same(denied))),
    ]);

    emitCache();
    codes.addError(denied);
    registrations.addError(denied);

    await expectations;
  });

  test('fails as unavailable when only populated staff cache is available offline', () async {
    final unavailable = isA<FirebaseException>().having((error) => error.code, 'code', 'unavailable');
    final expectations = Future.wait([
      expectLater(repository.watchCode().first, throwsA(unavailable)),
      expectLater(repository.watchRegistrations().first, throwsA(unavailable)),
    ]);

    emitCache();

    await expectations;
  });
}

class _SnapshotFirestore extends Fake implements FirebaseFirestore {
  _SnapshotFirestore(this.codes, this.registrations);

  final Stream<DocumentSnapshot<Map<String, dynamic>>> codes;
  final Stream<QuerySnapshot<Map<String, dynamic>>> registrations;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) => switch (collectionPath) {
    'supportLtSettings' => _SnapshotCollection(documentStream: codes),
    'supportLtRegistrations' => _SnapshotCollection(queryStream: registrations),
    _ => throw StateError('Unexpected collection: $collectionPath'),
  };
}

// Query fakes allow cache replay without relying on a real disk cache.
// ignore: subtype_of_sealed_class
class _SnapshotCollection extends Fake implements CollectionReference<Map<String, dynamic>> {
  _SnapshotCollection({this.documentStream, this.queryStream});

  final Stream<DocumentSnapshot<Map<String, dynamic>>>? documentStream;
  final Stream<QuerySnapshot<Map<String, dynamic>>>? queryStream;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _SnapshotDocumentReference(documentStream!);

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) => this;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    expect(includeMetadataChanges, isTrue, reason: 'Server confirmation may only change snapshot metadata.');
    return queryStream!;
  }
}

// Snapshot/reference fakes are necessary to replay cache and server metadata.
// ignore: subtype_of_sealed_class
class _SnapshotDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  _SnapshotDocumentReference(this.stream);

  final Stream<DocumentSnapshot<Map<String, dynamic>>> stream;

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    expect(includeMetadataChanges, isTrue, reason: 'Server confirmation may only change snapshot metadata.');
    return stream;
  }
}

// ignore: subtype_of_sealed_class
class _SourcedDocument extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _SourcedDocument(this.original, {required bool isFromCache}) : metadata = _Metadata(isFromCache: isFromCache);

  final DocumentSnapshot<Map<String, dynamic>> original;

  @override
  final SnapshotMetadata metadata;

  @override
  String get id => original.id;

  @override
  bool get exists => original.exists;

  @override
  Map<String, dynamic>? data() => original.data();
}

class _SourcedQuery extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _SourcedQuery(this.original, {required bool isFromCache}) : metadata = _Metadata(isFromCache: isFromCache);

  final QuerySnapshot<Map<String, dynamic>> original;

  @override
  final SnapshotMetadata metadata;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => original.docs;

  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges => const [];
}

class _Metadata extends Fake implements SnapshotMetadata {
  _Metadata({required this.isFromCache});

  @override
  final bool isFromCache;
}

class _UnusedFunctions extends Fake implements FirebaseFunctions {}
