import 'package:dashboard/feature/auth/data/provider/auth_repository.dart';
import 'package:data/user.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
