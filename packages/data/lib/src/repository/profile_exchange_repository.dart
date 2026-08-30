import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/profile_exchange.dart';
import 'firestore_watch.dart';

abstract interface class ProfileExchangeRepository {
  /// Emits [uid]'s exchange list, most recently exchanged first.
  Stream<List<ProfileExchange>> watchAll(String uid);

  /// Creates `users/{uid}/exchanges/{otherUid}` with `origin: 'scan'` after
  /// [uid] scans [otherUid]'s QR code.
  ///
  /// Writes directly without checking for an existing document first, so the
  /// call queues in the Firestore SDK's offline cache and [watchAll] reflects
  /// it immediately even offline. Re-scanning the same attendee sends the
  /// same write again; Firestore rules only allow changing `note` on an
  /// existing document, so the server rejects it as a permission error
  /// instead of rewriting `createdAt`/`origin`/`token`.
  Future<void> create({required String uid, required String otherUid, required String token});
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
      (snapshot) => snapshot.docs
          .map(
            (doc) => parseProfileExchangeDocument(
              id: doc.id,
              data: doc.data(),
              hasPendingWrites: doc.metadata.hasPendingWrites,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> create({required String uid, required String otherUid, required String token}) {
    return _exchanges(uid).doc(otherUid).set(<String, dynamic>{
      'createdAt': FieldValue.serverTimestamp(),
      'origin': 'scan',
      'token': token,
      'note': null,
    });
  }
}

/// Parses one exchange document, filling a still-pending `createdAt` with the
/// current time so the local echo of [FirestoreProfileExchangeRepository.create]
/// parses before the server timestamp resolves (mirrors
/// `FirestoreUserProfileRepository._toProfile`).
ProfileExchange parseProfileExchangeDocument({
  required String id,
  required Map<String, dynamic> data,
  required bool hasPendingWrites,
}) {
  final json = <String, dynamic>{...data, 'id': id};
  if (hasPendingWrites) {
    json['createdAt'] ??= DateTime.now();
  }
  return ProfileExchange.fromJson(json);
}
