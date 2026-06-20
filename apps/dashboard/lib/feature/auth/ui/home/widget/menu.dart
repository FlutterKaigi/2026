import 'package:dashboard/feature/auth/data/provider/auth_repository.dart';
import 'package:dashboard/feature/auth/data/provider/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum _MenuAction { signOut }

class Menu extends ConsumerWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;

    Future<void> signOut() async {
      ref.read(authRepositoryProvider).signOut();
    }

    return PopupMenuButton<_MenuAction>(
      tooltip: user?.email ?? '',
      icon: CircleAvatar(
        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
        child: user?.photoURL == null ? const Icon(Icons.person) : null,
      ),
      onSelected: (action) => switch (action) {
        _MenuAction.signOut => signOut(),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(user?.email ?? ''),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _MenuAction.signOut,
          child: Text('Sign Out'),
        ),
      ],
    );
  }
}
