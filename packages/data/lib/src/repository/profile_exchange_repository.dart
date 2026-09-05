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
  /// it immediately even offline. Re-scanning the same attendee (or scanning
  /// someone whose mirror already added them) sends the same write again;
  /// Firestore rules only allow changing `note` on an existing document, so
  /// the server rejects it with `permission-denied`, which this surfaces as
  /// [ProfileExchangeAlreadyExistsException] instead of a generic failure.
  Future<void> create({required String uid, required String otherUid, required String token});

  /// Removes `users/{uid}/exchanges/{otherUid}` from [uid]'s own list only.
  ///
  /// The mirror at `users/{otherUid}/exchanges/{uid}` is untouched by design
  /// (see the design doc's "相互交換 + 自分側だけの削除"): the exchange already
  /// happened, so the other attendee's list is unaffected by this side
  /// removing it from their own.
  Future<void> delete({required String uid, required String otherUid});

  /// Sets the free-form [note] on `users/{uid}/exchanges/{otherUid}`, visible
  /// only to [uid]. Pass `null` to clear it.
  Future<void> updateNote({required String uid, required String otherUid, required String? note});

  /// Counts [uid]'s exchange list via a Firestore aggregation query, without
  /// reading each document.
  Future<int> countAll(String uid);
}

/// Thrown by [ProfileExchangeRepository.create] when [otherUid] is already in
/// [uid]'s exchange list.
final class ProfileExchangeAlreadyExistsException implements Exception {
  const ProfileExchangeAlreadyExistsException();
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
  Future<void> create({required String uid, required String otherUid, required String token}) async {
    try {
      await _exchanges(uid).doc(otherUid).set(<String, dynamic>{
        'createdAt': FieldValue.serverTimestamp(),
        'origin': 'scan',
        'token': token,
        'note': null,
      });
    } on FirebaseException catch (exception) {
      if (exception.code == 'permission-denied') {
        throw const ProfileExchangeAlreadyExistsException();
      }
      rethrow;
    }
  }

  @override
  Future<void> delete({required String uid, required String otherUid}) => _exchanges(uid).doc(otherUid).delete();

  @override
  Future<void> updateNote({required String uid, required String otherUid, required String? note}) =>
      _exchanges(uid).doc(otherUid).update(<String, dynamic>{'note': note});

  @override
  Future<int> countAll(String uid) async {
    final snapshot = await _exchanges(uid).count().get();
    return snapshot.count ?? 0;
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
