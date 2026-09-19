import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pending cached registration times out instead of loading forever', (tester) async {
    final source = StreamController<DocumentSnapshot<Map<String, dynamic>>>();
    final repository = FirestoreSnsPostRepository(firestore: _Firestore(source.stream));
    final values = <SnsPostRegistration?>[];
    final errors = <Object>[];
    final subscription = repository.watch('attendee').listen(values.add, onError: errors.add);
    addTearDown(() async {
      await subscription.cancel();
      await source.close();
    });

    source.add(_Snapshot(pending: true));
    await tester.pump();
    expect(values, isEmpty);
    await tester.pump(const Duration(seconds: 11));
    expect(values, isEmpty);
    expect(errors, [isA<FirebaseException>().having((error) => error.code, 'code', 'unavailable')]);
  });

  testWidgets('only acknowledged snapshots update the saved registration', (tester) async {
    final source = StreamController<DocumentSnapshot<Map<String, dynamic>>>();
    final repository = FirestoreSnsPostRepository(firestore: _Firestore(source.stream));
    final values = <SnsPostRegistration?>[];
    final subscription = repository.watch('attendee').listen(values.add);
    addTearDown(() async {
      await subscription.cancel();
      await source.close();
    });

    source.add(_Snapshot(pending: true));
    await tester.pump();
    expect(values, isEmpty);
    source.add(_Snapshot(pending: false));
    await tester.pump();
    expect(values.single?.url, 'https://x.com/test/status/123');
    source.add(_Snapshot(pending: true, post: '456'));
    await tester.pump();
    expect(values, hasLength(1));
    source.add(_Snapshot(pending: false, post: '456'));
    await tester.pump();
    expect(values.last?.url, 'https://x.com/test/status/456');
    expect(values, hasLength(2));
  });
}

class _Firestore extends Fake implements FirebaseFirestore {
  _Firestore(this.source);
  final Stream<DocumentSnapshot<Map<String, dynamic>>> source;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) => _Collection(source);
}

// Metadata fakes reproduce offline pending writes, which FakeFirebaseFirestore cannot simulate.
// ignore: subtype_of_sealed_class
class _Collection extends Fake implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.source);
  final Stream<DocumentSnapshot<Map<String, dynamic>>> source;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _Document(source);
}

// ignore: subtype_of_sealed_class
class _Document extends Fake implements DocumentReference<Map<String, dynamic>> {
  _Document(this.source);
  final Stream<DocumentSnapshot<Map<String, dynamic>>> source;

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    expect(includeMetadataChanges, isTrue);
    return this.source;
  }
}

// ignore: subtype_of_sealed_class
class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot({required this.pending, this.post = '123'});
  final bool pending;
  final String post;

  @override
  bool get exists => true;

  @override
  SnapshotMetadata get metadata => _Metadata(pending);

  @override
  Map<String, dynamic> data() => {
    'url': 'https://x.com/test/status/$post',
    'companion': 'staff',
    'updatedAt': pending ? null : Timestamp.fromDate(DateTime.utc(2026)),
  };
}

class _Metadata extends Fake implements SnapshotMetadata {
  _Metadata(this.hasPendingWrites);
  @override
  final bool hasPendingWrites;
  @override
  bool get isFromCache => true;
}
