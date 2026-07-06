import 'package:app/core/util/window_size.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A top-level navigation destination rendered by [RootScaffold].
///
/// The order of destinations must match the order of the shell branches,
/// since tabs are switched by branch index.
class RootDestination {
  const RootDestination({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

/// Adaptive application shell.
///
/// Renders a [NavigationBar] on compact widths and a [NavigationRail] on
/// medium/expanded widths. Tabs switch via [StatefulNavigationShell.goBranch],
/// so the change is instant (no page transition animation) and each branch
/// keeps its navigation and scroll state.
class RootScaffold extends StatelessWidget {
  const RootScaffold({
    required this.navigationShell,
    required this.destinations,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<RootDestination> destinations;

  void _onSelected(int index) => navigationShell.goBranch(
    index,
    // Re-tapping the active tab resets that branch to its initial location.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;
    final windowSize = WindowSize.fromWidth(MediaQuery.sizeOf(context).width);

    if (windowSize == WindowSize.compact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: _onSelected,
          destinations: [
            for (final destination in destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                label: destination.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: windowSize == WindowSize.expanded,
            labelType: windowSize == WindowSize.expanded ? null : NavigationRailLabelType.all,
            selectedIndex: selectedIndex,
            onDestinationSelected: _onSelected,
            destinations: [
              for (final destination in destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  label: Text(destination.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
