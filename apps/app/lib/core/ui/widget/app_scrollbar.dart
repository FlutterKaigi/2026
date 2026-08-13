import 'package:flutter/material.dart';

/// Keeps the scrollbar aligned with the app content pane, even when the
/// scrollable itself is constrained to a readable max width.
class AppScrollbar extends StatelessWidget {
  const AppScrollbar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final behavior = ScrollConfiguration.of(context).copyWith(
      scrollbars: false,
    );

    return Scrollbar(
      child: ScrollConfiguration(
        behavior: behavior,
        child: child,
      ),
    );
  }
}
