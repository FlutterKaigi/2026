import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/sponsor.dart';
import 'firestore_watch.dart';

abstract interface class SponsorRepository {
  Stream<List<Sponsor>> watchAll({bool skipMalformedDocuments = false});
  Future<void> save(Sponsor sponsor);
  Future<void> delete(String id);
}

final class FirestoreSponsorRepository implements SponsorRepository {
  FirestoreSponsorRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('sponsors');

  @override
  Stream<List<Sponsor>> watchAll({bool skipMalformedDocuments = false}) {
    final query = _collection.orderBy('createdAt', descending: true);
    return watchFirestoreQuery(query).map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => parseSponsorDocument(
              id: doc.id,
              data: doc.data(),
              skipMalformedDocument: skipMalformedDocuments,
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
/// Public clients can skip an incomplete document so one dashboard draft does
/// not break the whole sponsor list. Other consumers keep strict conversion by
/// default. This is not an access-control boundary.
Sponsor? parseSponsorDocument({
  required String id,
  required Map<String, dynamic> data,
  required bool skipMalformedDocument,
}) {
  try {
    return Sponsor.fromJson(<String, dynamic>{...data, 'id': id});
  } on Object catch (error) {
    if (!skipMalformedDocument) {
      rethrow;
    }
    final name = data['name'];
    final description = data['description'];
    // Temporary release-build diagnostics. Remove after inspecting the Preview.
    // ignore: avoid_print
    print(
      '[SponsorParseError] id=$id error=$error '
      'keys=${data.keys.toList()} '
      'nameKeys=${name is Map ? name.keys.toList() : name.runtimeType} '
      'descriptionKeys=${description is Map ? description.keys.toList() : description.runtimeType} '
      'tier=${data['tier']} '
      'createdAtType=${data['createdAt'].runtimeType} '
      'updatedAtType=${data['updatedAt'].runtimeType}',
    );
    return null;
  }
}
