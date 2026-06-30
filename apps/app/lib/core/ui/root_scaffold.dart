import 'package:app/core/util/window_size.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A top-level navigation destination rendered by [RootScaffold].
class RootDestination {
  const RootDestination({
    required this.icon,
    required this.label,
    required this.location,
  });

  final IconData icon;
  final String label;
  final String location;
}

/// Adaptive application shell.
///
/// Renders a [NavigationBar] on compact widths and a [NavigationRail] on
/// medium/expanded widths, highlighting the destination whose location
/// matches the current router location.
class RootScaffold extends StatelessWidget {
  const RootScaffold({
    required this.navigator,
    required this.destinations,
    super.key,
  });

  final Widget navigator;
  final List<RootDestination> destinations;

  int _selectedIndex(String location) {
    final index = destinations.lastIndexWhere(
      (destination) => location.startsWith(destination.location),
    );
    return index < 0 ? 0 : index;
  }

  void _onSelected(BuildContext context, int index) => context.go(destinations[index].location);

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _selectedIndex(location);
    final windowSize = WindowSize.fromWidth(MediaQuery.sizeOf(context).width);

    if (windowSize == WindowSize.compact) {
      return Scaffold(
        body: navigator,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _onSelected(context, index),
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
            onDestinationSelected: (index) => _onSelected(context, index),
            destinations: [
              for (final destination in destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  label: Text(destination.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigator),
        ],
      ),
    );
  }
}
