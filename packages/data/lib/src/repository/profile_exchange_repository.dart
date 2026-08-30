import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/profile_exchange.dart';
import 'firestore_watch.dart';

abstract interface class ProfileExchangeRepository {
  /// Emits the signed-in attendee's exchange list, most recent first.
  Stream<List<ProfileExchange>> watchAll(String uid);

  /// Records that [uid] scanned [otherUid]'s QR code (or redeemed their
  /// 6-digit code), presenting [token] for server-side verification.
  ///
  /// A Cloud Function trigger verifies [token], mirrors the entry into
  /// `users/{otherUid}/exchanges/{uid}`, and clears the token on this
  /// document once verified. Does nothing if the pair already exchanged.
  Future<void> createFromScan({required String uid, required String otherUid, required String token});

  /// Updates the private [note] on `users/{uid}/exchanges/{otherUid}`.
  Future<void> updateNote({required String uid, required String otherUid, required String? note});

  /// Removes the entry from [uid]'s own list only; the other side is
  /// untouched.
  Future<void> delete({required String uid, required String otherUid});

  /// Number of attendees [uid] has exchanged with, via an aggregate `count()`
  /// query so the documents themselves are not read.
  Future<int> count(String uid);
}

final class FirestoreProfileExchangeRepository implements ProfileExchangeRepository {
  FirestoreProfileExchangeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _exchanges(String uid) =>
      _firestore.collection('users').doc(uid).collection('exchanges');

  @override
  Stream<List<ProfileExchange>> watchAll(String uid) {
    final query = _exchanges(uid).orderBy('createdAt', descending: true);
    return watchFirestoreQuery(query).map(
      (snapshot) => snapshot.docs.map((doc) => ProfileExchange.fromJson({...doc.data(), 'id': doc.id})).toList(),
    );
  }

  @override
  Future<void> createFromScan({required String uid, required String otherUid, required String token}) {
    return _exchanges(uid).doc(otherUid).set({
      'origin': 'scan',
      'token': token,
      'note': null,
      // ルールが `createdAt == request.time` を要求するため、必ずサーバー時刻を使う。
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateNote({required String uid, required String otherUid, required String? note}) {
    return _exchanges(uid).doc(otherUid).update({'note': note});
  }

  @override
  Future<void> delete({required String uid, required String otherUid}) => _exchanges(uid).doc(otherUid).delete();

  @override
  Future<int> count(String uid) async {
    final snapshot = await _exchanges(uid).count().get();
    return snapshot.count ?? 0;
  }
}
