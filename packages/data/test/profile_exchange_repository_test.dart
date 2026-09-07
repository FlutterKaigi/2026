import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data/data.dart';
import 'package:data/src/repository/profile_exchange_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseProfileExchangeDocument', () {
    test('parses a document with a resolved createdAt', () {
      final exchange = parseProfileExchangeDocument(
        id: 'other-uid-1',
        data: <String, dynamic>{
          'createdAt': DateTime.utc(2026, 8, 2),
          'origin': 'scan',
          'token': null,
          'note': null,
        },
        hasPendingWrites: false,
      );

      expect(exchange.id, 'other-uid-1');
      expect(exchange.createdAt, DateTime.utc(2026, 8, 2));
      expect(exchange.origin, ProfileExchangeOrigin.scan);
    });

    test('fills a still-pending createdAt with the current time', () {
      final before = DateTime.now();
      final exchange = parseProfileExchangeDocument(
        id: 'other-uid-1',
        data: <String, dynamic>{
          'createdAt': null,
          'origin': 'scan',
          'token': 'v1.other-uid-1.9999999999.signature',
        },
        hasPendingWrites: true,
      );
      final after = DateTime.now();

      expect(exchange.createdAt.isBefore(before), isFalse);
      expect(exchange.createdAt.isAfter(after), isFalse);
    });

    test('keeps a resolved createdAt untouched even with pending writes', () {
      final exchange = parseProfileExchangeDocument(
        id: 'other-uid-1',
        data: <String, dynamic>{
          'createdAt': DateTime.utc(2026, 8, 2),
          'origin': 'mirror',
        },
        hasPendingWrites: true,
      );

      expect(exchange.createdAt, DateTime.utc(2026, 8, 2));
    });
  });

  group('FirestoreProfileExchangeRepository', () {
    test('updateNote allows clearing the note back to null', () async {
      final firestore = FakeFirebaseFirestore();
      await _exchanges(firestore, 'uid-1').doc('uid-2').set(_exchangeData(note: 'a note'));
      final repository = FirestoreProfileExchangeRepository(firestore: firestore);

      await repository.updateNote(uid: 'uid-1', otherUid: 'uid-2', note: null);

      final snapshot = await _exchanges(firestore, 'uid-1').doc('uid-2').get();
      expect(snapshot.data()?['note'], isNull);
    });

    test('countAll returns 0 for an empty collection', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreProfileExchangeRepository(firestore: firestore);

      expect(await repository.countAll('uid-1'), 0);
    });

    test('delete removes only the caller\'s own side, leaving the other attendee\'s mirror untouched', () async {
      final firestore = FakeFirebaseFirestore();
      await _exchanges(firestore, 'uid-1').doc('uid-2').set(_exchangeData(origin: 'scan'));
      await _exchanges(firestore, 'uid-2').doc('uid-1').set(_exchangeData(origin: 'mirror'));
      final repository = FirestoreProfileExchangeRepository(firestore: firestore);

      await repository.delete(uid: 'uid-1', otherUid: 'uid-2');

      final own = await _exchanges(firestore, 'uid-1').doc('uid-2').get();
      final mirror = await _exchanges(firestore, 'uid-2').doc('uid-1').get();
      expect(own.exists, isFalse);
      expect(mirror.exists, isTrue);
    });
  });
}

CollectionReference<Map<String, dynamic>> _exchanges(FirebaseFirestore firestore, String uid) =>
    firestore.collection('users').doc(uid).collection('exchanges');

Map<String, dynamic> _exchangeData({String origin = 'scan', String? note}) => <String, dynamic>{
  'createdAt': Timestamp.fromDate(DateTime.utc(2026, 8, 2)),
  'origin': origin,
  'token': null,
  'note': note,
};
