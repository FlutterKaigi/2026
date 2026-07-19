import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/sponsor.dart';

abstract interface class SponsorRepository {
  Stream<List<Sponsor>> watchAll();
  Future<void> save(Sponsor sponsor);
  Future<void> delete(String id);
}

final class FirestoreSponsorRepository implements SponsorRepository {
  FirestoreSponsorRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('sponsors');

  @override
  Stream<List<Sponsor>> watchAll() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) Sponsor.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }

  @override
  Future<void> save(Sponsor sponsor) async {
    final data = sponsor.toJson()
      ..remove('id')
      ..remove('createdAt')
      ..remove('updatedAt');
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (sponsor.isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await _collection.add(data);
    } else {
      await _collection.doc(sponsor.id).set(data, SetOptions(merge: true));
    }
  }

  @override
  Future<void> delete(String id) => _collection.doc(id).delete();
}
