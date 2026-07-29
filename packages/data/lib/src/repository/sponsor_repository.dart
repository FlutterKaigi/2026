import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/sponsor.dart';
import 'firestore_watch.dart';

abstract interface class SponsorRepository {
  Stream<List<Sponsor>> watchAll({bool excludeUnsupportedTiers = false});
  Future<void> save(Sponsor sponsor);
  Future<void> delete(String id);
}

final class FirestoreSponsorRepository implements SponsorRepository {
  FirestoreSponsorRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('sponsors');

  @override
  Stream<List<Sponsor>> watchAll({bool excludeUnsupportedTiers = false}) {
    final query = _collection.orderBy('createdAt', descending: true);
    return watchFirestoreQuery(query).map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => parseSponsorDocument(
              id: doc.id,
              data: doc.data(),
              excludeUnsupportedTiers: excludeUnsupportedTiers,
            ),
          )
          .nonNulls
          .toList(),
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

/// Parses one sponsor document without treating a missing logo as invalid.
///
/// Public clients can exclude tiers they do not support yet. Other malformed
/// fields keep surfacing as conversion errors, and other consumers keep strict
/// tier conversion by default. This is not an access-control boundary.
Sponsor? parseSponsorDocument({
  required String id,
  required Map<String, dynamic> data,
  required bool excludeUnsupportedTiers,
}) {
  final tier = data['tier'];
  if (excludeUnsupportedTiers && tier is String && !SponsorTier.values.any((value) => value.name == tier)) {
    return null;
  }
  return Sponsor.fromJson(<String, dynamic>{...data, 'id': id});
}
