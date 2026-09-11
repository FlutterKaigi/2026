import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final supportLtRepositoryProvider = Provider<SupportLtRepository>(
  (ref) => FirebaseSupportLtRepository(),
);

/// A separate live subscription for each account keeps a previous attendee's
/// registration out of the next attendee's UI when accounts change.
/// Only signed-in views watch this provider.
final supportLtRegistrationProvider = StreamProvider.autoDispose.family<SupportLtRegistration?, String>(
  (ref, uid) => ref.watch(supportLtRepositoryProvider).watchRegistration(uid),
  // The page shows a retry button; automatic resubscription would wait on
  // another initial-snapshot timeout behind the error view.
  retry: (_, _) => null,
);
