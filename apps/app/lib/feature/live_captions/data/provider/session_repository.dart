import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides the [SessionRepository] implementation backed by Firestore.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => FirestoreSessionRepository(),
);
