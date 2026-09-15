import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data/data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('watchMany emits an empty list without profile IDs', () async {
    final repository = FirestoreUserProfileRepository(firestore: FakeFirebaseFirestore());
    expect(await repository.watchMany([]).single, isEmpty);
  });

  test('watchMany combines batches, deduplicates IDs, and reflects edits and deletion', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreUserProfileRepository(firestore: firestore);
    final ids = [for (var i = 0; i < 40; i++) 'user-${i.toString().padLeft(2, '0')}'];
    for (final uid in ids) {
      await firestore.doc('users/$uid').set({
        'displayName': uid,
        'countryOrRegion': 'JP',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026)),
      });
    }
    final profiles = StreamIterator(repository.watchMany([...ids, ids.first, 'missing']));
    addTearDown(profiles.cancel);
    expect(await profiles.moveNext(), isTrue);
    expect(profiles.current.map((profile) => profile.id), unorderedEquals(ids));

    // The last profile belongs to a separate query from the first one.
    await firestore.doc('users/${ids.last}').update({'countryOrRegion': 'US'});
    expect(await profiles.moveNext(), isTrue);
    expect(profiles.current, hasLength(40));
    expect(profiles.current.singleWhere((profile) => profile.id == ids.last).countryOrRegion, 'US');

    await firestore.doc('users/${ids.first}').delete();
    expect(await profiles.moveNext(), isTrue);
    expect(profiles.current.map((profile) => profile.id), unorderedEquals(ids.skip(1)));
  });
}
