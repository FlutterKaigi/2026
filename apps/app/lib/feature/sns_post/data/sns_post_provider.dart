import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final snsPostRepositoryProvider = Provider<SnsPostRepository>((ref) => FirestoreSnsPostRepository());

final snsPostRegistrationProvider = StreamProvider.autoDispose.family<SnsPostRegistration?, String>(
  (ref, uid) => ref.watch(snsPostRepositoryProvider).watch(uid),
  retry: (_, _) => null,
);
