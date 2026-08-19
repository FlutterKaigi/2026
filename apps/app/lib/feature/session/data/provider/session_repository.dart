import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides access to the Firestore `sessions` collection.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => FirestoreSessionRepository(),
);
