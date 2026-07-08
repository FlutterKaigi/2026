import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/quiz_event.dart';

abstract interface class QuizEventRepository {
  Stream<List<QuizEvent>> watchAll();
  Stream<QuizEvent?> watchById(String eventId);
  Future<void> save(QuizEvent event);
}

final class FirestoreQuizEventRepository implements QuizEventRepository {
  FirestoreQuizEventRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('quizEvents');

  @override
  Stream<List<QuizEvent>> watchAll() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) QuizEvent.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }

  @override
  Stream<QuizEvent?> watchById(String eventId) {
    return _collection.doc(eventId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return QuizEvent.fromJson(<String, dynamic>{...data, 'id': snapshot.id});
    });
  }

  @override
  Future<void> save(QuizEvent event) async {
    final data = event.toJson()
      ..remove('id')
      ..remove('createdAt')
      ..remove('updatedAt');
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (event.isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await _collection.add(data);
    } else {
      await _collection.doc(event.id).set(data, SetOptions(merge: true));
    }
  }
}
