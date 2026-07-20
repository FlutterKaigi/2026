import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/live_caption.dart';

abstract interface class LiveCaptionsRepository {
  /// Streams the room document, or `null` while it does not exist.
  Stream<LiveCaptionRoom?> watchRoom(String roomId);

  /// Streams every room document (used for live indicators on pickers).
  Stream<List<LiveCaptionRoom>> watchRooms();

  /// Streams the latest [limit] finalized segments in chronological order.
  Stream<List<LiveCaptionSegment>> watchLatestSegments(String roomId, {int limit});
}

final class FirestoreLiveCaptionsRepository implements LiveCaptionsRepository {
  FirestoreLiveCaptionsRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rooms => _firestore.collection('live_captions');

  @override
  Stream<LiveCaptionRoom?> watchRoom(String roomId) {
    return _rooms.doc(roomId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return LiveCaptionRoom.fromJson(<String, dynamic>{...data, 'id': snapshot.id});
    });
  }

  @override
  Stream<List<LiveCaptionRoom>> watchRooms() {
    return _rooms.snapshots().map(
      (snapshot) => [
        for (final doc in snapshot.docs) LiveCaptionRoom.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
      ],
    );
  }

  @override
  Stream<List<LiveCaptionSegment>> watchLatestSegments(String roomId, {int limit = 50}) {
    // The newest N are fetched by descending `createdAt` (set by the server on
    // every segment) and re-reversed here. Document ids (`{connectionStartMs}-{seq6}`)
    // also sort chronologically, but the Firestore emulator rejects descending
    // `__name__` scans, so the timestamp field is used instead.
    return _rooms
        .doc(roomId)
        .collection('segments')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs.reversed)
              LiveCaptionSegment.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }
}
