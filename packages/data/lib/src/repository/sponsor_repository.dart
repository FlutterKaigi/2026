import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/sponsor.dart';
import 'firestore_watch.dart';

abstract interface class SponsorRepository {
  Stream<List<Sponsor>> watchAll({bool requirePrimaryLogo = false});
  Future<void> save(Sponsor sponsor);
  Future<void> delete(String id);
}

final class FirestoreSponsorRepository implements SponsorRepository {
  FirestoreSponsorRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('sponsors');

  @override
  Stream<List<Sponsor>> watchAll({bool requirePrimaryLogo = false}) {
    final query = _collection.orderBy('createdAt', descending: true);
    return watchFirestoreQuery(query).map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => parseSponsorDocument(
              id: doc.id,
              data: doc.data(),
              requirePrimaryLogo: requirePrimaryLogo,
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

/// Parses one sponsor document after applying the requested publication gate.
///
/// The logo check intentionally runs before strict model conversion so a draft
/// that is still being completed in the dashboard cannot break public clients.
Sponsor? parseSponsorDocument({
  required String id,
  required Map<String, dynamic> data,
  required bool requirePrimaryLogo,
}) {
  final primaryLogoUrl = data['primaryLogoUrl'];
  if (requirePrimaryLogo && (primaryLogoUrl is! String || primaryLogoUrl.trim().isEmpty)) {
    return null;
  }
  return Sponsor.fromJson(<String, dynamic>{...data, 'id': id});
}
