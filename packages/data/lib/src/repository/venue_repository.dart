import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/venue.dart';

abstract interface class VenueRepository {
  Stream<List<Venue>> watchAll();
  Future<void> save(Venue venue);
  Future<void> delete(String id);
}

final class FirestoreVenueRepository implements VenueRepository {
  FirestoreVenueRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('venues');

  @override
  Stream<List<Venue>> watchAll() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) Venue.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }

  @override
  Future<void> save(Venue venue) async {
    final data = venue.toJson()
      ..remove('id')
      ..remove('createdAt')
      ..remove('updatedAt');
    if (data['order'] == null) data.remove('order');
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (venue.isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await _collection.add(data);
    } else {
      await _collection.doc(venue.id).set(data, SetOptions(merge: true));
    }
  }

  @override
  Future<void> delete(String id) => _collection.doc(id).delete();
}
