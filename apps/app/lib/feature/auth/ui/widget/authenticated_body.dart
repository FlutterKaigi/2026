import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Gates account content and discards its state when the signed-in user changes.
class AuthenticatedBody extends ConsumerWidget {
  const AuthenticatedBody({required this.signedOut, required this.builder, super.key});

  final Widget signedOut;
  final Widget Function(String uid) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(authStateChangesProvider)) {
    AsyncData(value: null) => signedOut,
    AsyncData(:final value?) => KeyedSubtree(key: ValueKey(value.uid), child: builder(value.uid)),
    AsyncError(:final error) => AppErrorView(error: error, onRetry: () => ref.invalidate(authStateChangesProvider)),
    _ => const Center(child: CircularProgressIndicator.adaptive()),
  };
}
