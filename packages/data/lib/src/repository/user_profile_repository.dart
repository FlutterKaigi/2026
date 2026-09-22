import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../model/user_profile.dart';
import 'firestore_watch.dart';

abstract interface class UserProfileRepository {
  /// Emits the profile stored for [uid], or `null` while none exists.
  Stream<UserProfile?> watch(String uid);

  /// Watches distinct profiles in batches; missing profiles are omitted.
  Stream<List<UserProfile>> watchMany(Iterable<String> uids);

  /// Creates or updates the profile for [UserProfile.id].
  ///
  /// `createdAt` is preserved on update and `updatedAt` is always set by the
  /// server, so the timestamps carried by [profile] are ignored.
  Future<void> save(UserProfile profile);

  /// Deletes the profile for [uid]. Missing documents are ignored.
  Future<void> delete(String uid);
}

final class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('users');

  @override
  Stream<UserProfile?> watch(String uid) => watchFirestoreDocument(_collection.doc(uid)).map(_toProfile);

  @override
  Stream<List<UserProfile>> watchMany(Iterable<String> uids) {
    final ids = uids.toSet().toList()..sort();
    if (ids.isEmpty) {
      return Stream.value(const []);
    }
    // Firestore permits up to 30 document IDs in one `in` query.
    const batchSize = 30;
    final batches = <Stream<List<UserProfile>>>[];
    for (var start = 0; start < ids.length; start += batchSize) {
      final batch = ids.skip(start).take(batchSize).toList();
      batches.add(
        watchFirestoreQuery(
          _collection.where(FieldPath.documentId, whereIn: batch),
        ).map((snapshot) => [for (final document in snapshot.docs) _toProfile(document)!]),
      );
    }
    return Rx.combineLatestList(batches).map((profiles) => profiles.expand((batch) => batch).toList());
  }

  /// Parses [snapshot], or returns `null` for a missing document.
  ///
  /// `snapshots()` reports pending `FieldValue.serverTimestamp()` writes as
  /// `null` (the SDK pins `ServerTimestampBehavior.none` for listeners), so
  /// the local echo of a save would fail to parse. Fill those fields with the
  /// current time until the server acknowledges the write, mirroring
  /// `ServerTimestampBehavior.estimate`.
  static UserProfile? _toProfile(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!snapshot.exists) {
      return null;
    }
    final data = <String, dynamic>{...snapshot.data()!, 'id': snapshot.id};
    if (snapshot.metadata.hasPendingWrites) {
      final now = DateTime.now();
      data['createdAt'] ??= now;
      data['updatedAt'] ??= now;
    }
    return UserProfile.fromJson(data);
  }

  @override
  Future<void> save(UserProfile profile) async {
    final data = profile.toJson()
      ..remove('id')
      ..remove('createdAt')
      ..remove('updatedAt');
    data['updatedAt'] = FieldValue.serverTimestamp();

    final reference = _collection.doc(profile.id);
    // 作成と更新を同じ呼び出しで扱うため、既存ドキュメントの有無を確認して
    // createdAt を初回だけ設定する。書き込むのは本人だけなので get と set の間の
    // 競合は実質起きない（起きても rules が createdAt の変更を拒否する）。
    // runTransaction は cloud_firestore の iOS 実装で "Future already completed"
    // を投げる不具合があるため使わない。
    final snapshot = await reference.get();
    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await reference.set(data, SetOptions(merge: true));
  }

  @override
  Future<void> delete(String uid) => _collection.doc(uid).delete();
}
