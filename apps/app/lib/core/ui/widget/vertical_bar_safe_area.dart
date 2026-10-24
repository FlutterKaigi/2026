import 'package:app/core/util/vertical_bar_edge.dart';
import 'package:flutter/material.dart';

/// Keeps a full-screen page out of iOS's vertical bar (iPhone Duo), painting
/// the scaffold background behind the bar so the page still reaches the edge
/// of the screen.
///
/// Pages in the navigation shell get the same treatment from `RootScaffold`;
/// this is for the top-level routes shown without it.
class VerticalBarSafeArea extends StatelessWidget {
  const VerticalBarSafeArea({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final edge = VerticalBarEdge.of(context);
    // Keep the same widgets with or without the bar: rotating or unfolding
    // the device must not rebuild the page and run its effects again.
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        left: edge == VerticalBarEdge.left,
        top: false,
        right: edge == VerticalBarEdge.right,
        bottom: false,
        child: child,
      ),
    );
  }
}
