import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:data/user.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Emits the signed-in Firebase [User], or `null` while signed out.
final authStateChangesProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
