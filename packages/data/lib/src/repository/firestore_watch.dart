import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

const _initialSnapshotTimeout = Duration(seconds: 10);

/// Watches [query] with one listener while preserving offline-first behavior.
///
/// A populated cache is emitted immediately. An empty cache is held until the
/// server confirms that the collection is genuinely empty, so an unreachable
/// backend is not mistaken for an empty collection.
Stream<QuerySnapshot<Map<String, dynamic>>> watchFirestoreQuery(
  Query<Map<String, dynamic>> query, {
  bool fallbackToEmptyCacheOnTimeout = false,
}) => waitForUsableInitialSnapshot(
  query.snapshots(includeMetadataChanges: true),
  isUsableInitialSnapshot: (snapshot) => snapshot.docs.isNotEmpty || !snapshot.metadata.isFromCache,
  shouldForwardAfterInitial: (snapshot) => snapshot.docChanges.isNotEmpty,
  useLastRejectedValueOnTimeout: fallbackToEmptyCacheOnTimeout,
);

/// Suppresses unusable initial values until [isUsableInitialSnapshot] accepts
/// one, then forwards the rest of [source] unchanged using the same listener.
///
/// This is public within `src` so the timeout and stream behavior can be tested
/// without constructing Firestore platform snapshots.
Stream<T> waitForUsableInitialSnapshot<T>(
  Stream<T> source, {
  required bool Function(T value) isUsableInitialSnapshot,
  bool Function(T value)? shouldForwardAfterInitial,
  bool useLastRejectedValueOnTimeout = false,
  Duration timeout = _initialSnapshotTimeout,
}) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  Timer? timeoutTimer;
  var initialSnapshotResolved = false;
  var terminated = false;
  var cancelRequested = false;
  var hasRejectedValue = false;
  late T lastRejectedValue;

  Future<void> terminateWithError(
    Object error,
    StackTrace stackTrace,
  ) async {
    if (terminated) {
      return;
    }
    terminated = true;
    cancelRequested = true;
    timeoutTimer?.cancel();
    controller.addError(error, stackTrace);
    await subscription?.cancel();
    await controller.close();
  }

  controller = StreamController<T>(
    onListen: () {
      timeoutTimer = Timer(timeout, () {
        if (useLastRejectedValueOnTimeout && hasRejectedValue) {
          initialSnapshotResolved = true;
          controller.add(lastRejectedValue);
          return;
        }
        unawaited(
          terminateWithError(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'unavailable',
              message: 'The initial Firestore snapshot timed out.',
            ),
            StackTrace.current,
          ),
        );
      });

      subscription = source.listen(
        (value) {
          if (terminated) {
            return;
          }
          if (initialSnapshotResolved) {
            if (shouldForwardAfterInitial?.call(value) ?? true) {
              controller.add(value);
            }
            return;
          }
          if (!isUsableInitialSnapshot(value)) {
            hasRejectedValue = true;
            lastRejectedValue = value;
            return;
          }
          initialSnapshotResolved = true;
          timeoutTimer?.cancel();
          controller.add(value);
        },
        onError: (Object error, StackTrace stackTrace) => unawaited(
          terminateWithError(error, stackTrace),
        ),
        onDone: () {
          timeoutTimer?.cancel();
          if (terminated) {
            return;
          }
          if (!initialSnapshotResolved) {
            unawaited(
              terminateWithError(
                FirebaseException(
                  plugin: 'cloud_firestore',
                  code: 'unavailable',
                  message: 'The Firestore snapshot stream ended before loading.',
                ),
                StackTrace.current,
              ),
            );
          } else {
            terminated = true;
            unawaited(controller.close());
          }
        },
      );
      if (cancelRequested) {
        unawaited(subscription?.cancel());
      }
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () async {
      terminated = true;
      cancelRequested = true;
      timeoutTimer?.cancel();
      await subscription?.cancel();
    },
  );

  return controller.stream;
}
