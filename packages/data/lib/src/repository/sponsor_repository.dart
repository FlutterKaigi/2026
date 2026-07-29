import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
    final query = _collection.orderBy('createdAt', descending: true);
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => parsePublishedSponsor(
              id: doc.id,
              data: doc.data(),
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

/// Parses a sponsor only when the document is ready for public display.
///
/// Sponsor documents are filled in progressively in the dashboard. Matching
/// the website publication gate prevents an incomplete draft from breaking the
/// entire sponsor wall while its logo or required localized fields are pending.
Sponsor? parsePublishedSponsor({
  required String id,
  required Map<String, dynamic> data,
}) {
  final primaryLogoUrl = data['primaryLogoUrl'];
  if (primaryLogoUrl is! String || primaryLogoUrl.trim().isEmpty) {
    return null;
  }

  try {
    return Sponsor.fromJson(<String, dynamic>{...data, 'id': id});
  } on Object catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'data',
        context: ErrorDescription(
          'while parsing published sponsor document $id',
        ),
      ),
    );
    return null;
  }
}
