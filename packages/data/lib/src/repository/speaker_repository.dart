import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/speaker.dart';

abstract interface class SpeakerRepository {
  Stream<List<Speaker>> watchAll();
  Future<void> save(Speaker speaker);
  Future<void> delete(String id);
}

final class FirestoreSpeakerRepository implements SpeakerRepository {
  FirestoreSpeakerRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('speakers');

  @override
  Stream<List<Speaker>> watchAll() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) Speaker.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }

  @override
  Future<void> save(Speaker speaker) async {
    final data = speaker.toJson()
      ..remove('id')
      ..remove('createdAt')
      ..remove('updatedAt');
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (speaker.isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await _collection.add(data);
    } else {
      await _collection.doc(speaker.id).set(data, SetOptions(merge: true));
    }
  }

  @override
  Future<void> delete(String id) => _collection.doc(id).delete();
}
