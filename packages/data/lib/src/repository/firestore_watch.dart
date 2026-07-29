import 'package:cloud_firestore/cloud_firestore.dart';

/// Watches [query] while avoiding an unconfirmed empty-cache result.
///
/// Cached data is emitted immediately. An empty cache is held until Firestore
/// confirms the result from the server, while the SDK listener remains active
/// for App Check, retry, and reconnection handling.
Stream<QuerySnapshot<Map<String, dynamic>>> watchFirestoreQuery(
  Query<Map<String, dynamic>> query,
) => waitForUsableInitialSnapshot(
  query.snapshots(includeMetadataChanges: true),
  isUsableInitialSnapshot: (snapshot) => snapshot.docs.isNotEmpty || !snapshot.metadata.isFromCache,
  shouldForwardAfterInitial: (snapshot) => snapshot.docChanges.isNotEmpty,
);

/// Suppresses unusable initial values without adding a timeout or replacing
/// errors emitted by [source].
Stream<T> waitForUsableInitialSnapshot<T>(
  Stream<T> source, {
  required bool Function(T value) isUsableInitialSnapshot,
  bool Function(T value)? shouldForwardAfterInitial,
}) {
  var initialSnapshotResolved = false;

  return source.where((value) {
    if (!initialSnapshotResolved) {
      if (!isUsableInitialSnapshot(value)) {
        return false;
      }
      initialSnapshotResolved = true;
      return true;
    }

    return shouldForwardAfterInitial?.call(value) ?? true;
  });
}
