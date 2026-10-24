import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/util/reserved_regions.dart';
import 'package:app/core/util/vertical_bar_edge.dart';
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

/// Height kept free at the top of the vertical bar for the camera when UIKit
/// cannot report where it is. The clock and status icons below it stay clear
/// because the tabs sit at the bottom.
const double _verticalBarCameraExtent = 72;

/// Adaptive application shell.
///
/// Renders a [NavigationBar] on compact widths and a [NavigationRail] on
/// medium/expanded widths. When iOS shows its status bar as a vertical bar
/// (iPhone Duo), the tabs move into that bar below the status icons instead,
/// and the pages stop at its edge. Tabs switch via
/// [StatefulNavigationShell.goBranch], so the change is instant (no page
/// transition animation) and each branch keeps its navigation and scroll
/// state.
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

  List<NavigationRailDestination> get _railDestinations => [
    for (final destination in destinations)
      NavigationRailDestination(
        icon: Icon(destination.icon),
        label: Text(destination.label),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;
    final verticalBarEdge = VerticalBarEdge.of(context);
    if (verticalBarEdge != null) {
      return _buildWithVerticalBar(context, verticalBarEdge);
    }

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
            destinations: _railDestinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }

  Widget _buildWithVerticalBar(BuildContext context, VerticalBarEdge edge) {
    final padding = MediaQuery.paddingOf(context);
    final onRight = edge == VerticalBarEdge.right;
    final barWidth = onRight ? padding.right : padding.left;

    // The pages end at the bar, while the scaffold background continues
    // underneath it.
    final body = Expanded(
      child: Builder(
        // Read the media query below the Scaffold, which has already made
        // room for the keyboard; the pages must not do so a second time.
        builder: (context) => MediaQuery.removePadding(
          context: context,
          removeLeft: !onRight,
          removeRight: onRight,
          child: navigationShell,
        ),
      ),
    );
    final bar = SizedBox(
      width: barWidth,
      child: _VerticalBarTabs(
        edge: edge,
        rail: NavigationRail(
          minWidth: barWidth,
          backgroundColor: Colors.transparent,
          // Like the system tab bar, the tabs sit at the bottom of the bar.
          groupAlignment: 1,
          labelType: NavigationRailLabelType.all,
          scrollable: true,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onSelected,
          destinations: _railDestinations,
        ),
      ),
    );

    return Scaffold(
      body: Row(children: onRight ? [body, bar] : [bar, body]),
    );
  }
}

/// Places [rail] in the vertical bar, clear of the camera that iOS reserves at
/// one end of it. The camera is at the top of the bar or, when the closed
/// device is turned the other way, at the bottom.
class _VerticalBarTabs extends StatefulWidget {
  const _VerticalBarTabs({required this.edge, required this.rail});

  final VerticalBarEdge edge;
  final Widget rail;

  @override
  State<_VerticalBarTabs> createState() => _VerticalBarTabsState();
}

class _VerticalBarTabsState extends State<_VerticalBarTabs> with WidgetsBindingObserver {
  List<Rect>? _occlusions;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_updateOcclusions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // UIKit does not announce changes to the reserved regions, so ask again
  // whenever the view is laid out again (rotation, fold, split, or anything
  // else that resizes the Flutter view) and when the app comes back.
  @override
  void didChangeMetrics() => unawaited(_updateOcclusions());

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_updateOcclusions());
    }
  }

  Future<void> _updateOcclusions() async {
    final request = ++_request;
    final occlusions = await fetchOcclusions();
    // Only the latest answer describes the current screen.
    if (mounted && request == _request) {
      setState(() => _occlusions = occlusions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    var top = _verticalBarCameraExtent;
    var bottom = padding.bottom;
    final occlusions = _occlusions;
    if (occlusions != null) {
      top = 0;
      final barRect = widget.edge == VerticalBarEdge.right
          ? Rect.fromLTRB(size.width - padding.right, 0, size.width, size.height)
          : Rect.fromLTRB(0, 0, padding.left, size.height);
      for (final occlusion in occlusions.where(barRect.overlaps)) {
        if (occlusion.center.dy < size.height / 2) {
          top = math.max(top, occlusion.bottom);
        } else {
          bottom = math.max(bottom, size.height - occlusion.top);
        }
      }
    }
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeRight: true,
        removeBottom: true,
        child: widget.rail,
      ),
    );
  }
}
