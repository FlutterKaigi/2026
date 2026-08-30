import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides access to the Firestore `users/{uid}/exchanges` subcollection.
final profileExchangeRepositoryProvider = Provider<ProfileExchangeRepository>(
  (ref) => FirestoreProfileExchangeRepository(),
);
