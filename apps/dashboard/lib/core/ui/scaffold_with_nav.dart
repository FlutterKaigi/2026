import 'package:dashboard/core/router/paths.dart';
import 'package:dashboard/feature/auth/data/provider/auth_repository.dart';
import 'package:dashboard/feature/auth/data/provider/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('FlutterKaigi 2026 管理ダッシュボード'),
        actions: [const _UserMenu()],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Row(
        children: [
          _SideNav(currentLocation: location),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

enum _MenuAction { signOut }

class _UserMenu extends ConsumerWidget {
  const _UserMenu();

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

class _NavItem {
  const _NavItem({required this.label, required this.icon, required this.path});

  final String label;
  final IconData icon;
  final String path;
}

const _navItems = [
  _NavItem(label: 'ホーム', icon: Icons.dashboard, path: AppPaths.home),
  _NavItem(label: 'ニュース', icon: Icons.newspaper, path: AppPaths.news),
  _NavItem(label: '会場', icon: Icons.location_on, path: AppPaths.venues),
  _NavItem(label: 'スピーカー', icon: Icons.person, path: AppPaths.speakers),
  _NavItem(label: 'スタッフ', icon: Icons.group, path: AppPaths.staff),
  _NavItem(label: 'タイムライン', icon: Icons.schedule, path: AppPaths.timeline),
  _NavItem(label: 'セッション', icon: Icons.event, path: AppPaths.sessions),
];

class _SideNav extends StatelessWidget {
  const _SideNav({required this.currentLocation});

  final String currentLocation;

  int get _selectedIndex {
    for (var i = _navItems.length - 1; i >= 0; i--) {
      final path = _navItems[i].path;
      if (path == AppPaths.home) {
        if (currentLocation == AppPaths.home) return i;
      } else if (currentLocation.startsWith(path)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _selectedIndex;

    return NavigationRail(
      selectedIndex: index,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (i) => context.go(_navItems[i].path),
      destinations: [
        for (final item in _navItems)
          NavigationRailDestination(
            icon: Icon(item.icon),
            label: Text(item.label),
          ),
      ],
    );
  }
}
