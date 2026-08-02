import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/contributor.dart';
import 'firestore_watch.dart';

abstract interface class ContributorRepository {
  Stream<List<Contributor>> watchAll();
}

final class FirestoreContributorRepository implements ContributorRepository {
  FirestoreContributorRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('contributors');

  @override
  Stream<List<Contributor>> watchAll() {
    final query = _collection.orderBy('contributions', descending: true);
    return watchFirestoreQuery(query).map(
      (snapshot) => [
        for (final doc in snapshot.docs) parseContributorDocument(id: doc.id, data: doc.data()),
      ],
    );
  }
}

/// Converts one Firestore `contributors` document into a [Contributor].
///
/// The document ID is the GitHub login and wins over any `login` field in the
/// document body.
Contributor parseContributorDocument({
  required String id,
  required Map<String, dynamic> data,
}) => Contributor.fromJson(<String, dynamic>{...data, 'login': id});
