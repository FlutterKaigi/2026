import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Emits the signed-in user's [UserProfile], or `null` while signed out or
/// before the user has created one.
///
/// Stays loading while the auth state itself is still loading so callers can
/// distinguish "not signed in" from "not resolved yet".
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return switch (authState) {
    AsyncData(:final value) =>
      value == null ? Stream.value(null) : ref.watch(userProfileRepositoryProvider).watch(value.uid),
    AsyncError(:final error, :final stackTrace) => Stream<UserProfile?>.error(error, stackTrace),
    _ => const Stream<UserProfile?>.empty(),
  };
});
