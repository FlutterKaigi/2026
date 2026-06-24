import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/timeline_event.dart';

abstract interface class TimelineEventRepository {
  Stream<List<TimelineEvent>> watchAll();
  Future<void> save(TimelineEvent timelineEvent);
  Future<void> delete(String id);
}

final class FirestoreTimelineEventRepository implements TimelineEventRepository {
  FirestoreTimelineEventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('timelineEvents');

  @override
  Stream<List<TimelineEvent>> watchAll() {
    return _collection
        .orderBy('startsAt')
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) TimelineEvent.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }

  @override
  Future<void> save(TimelineEvent timelineEvent) async {
    final data = timelineEvent.toJson()
      ..remove('id')
      ..remove('createdAt')
      ..remove('updatedAt');
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (timelineEvent.isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await _collection.add(data);
    } else {
      await _collection.doc(timelineEvent.id).set(data, SetOptions(merge: true));
    }
  }

  @override
  Future<void> delete(String id) => _collection.doc(id).delete();
}
