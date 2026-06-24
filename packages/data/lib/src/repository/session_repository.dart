import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/session.dart';

abstract interface class SessionRepository {
  Stream<List<Session>> watchAll();
  Future<void> save(Session session);
  Future<void> delete(String id);
}

final class FirestoreSessionRepository implements SessionRepository {
  FirestoreSessionRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('sessions');

  @override
  Stream<List<Session>> watchAll() {
    return _collection
        .orderBy('startsAt')
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) Session.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }

  @override
  Future<void> save(Session session) async {
    final data = session.toJson()
      ..remove('id')
      ..remove('createdAt')
      ..remove('updatedAt');
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (session.isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await _collection.add(data);
    } else {
      await _collection.doc(session.id).set(data, SetOptions(merge: true));
    }
  }

  @override
  Future<void> delete(String id) => _collection.doc(id).delete();
}
