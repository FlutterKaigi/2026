import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:flutter/material.dart';

/// Scrollable, width-constrained content for account forms and summaries.
class AppPageContent extends StatelessWidget {
  const AppPageContent({
    required this.maxWidth,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
    this.centerVertically = false,
    super.key,
  });

  final double maxWidth;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool centerVertically;

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
    return AppScrollbar(child: centerVertically ? Center(child: content) : content);
  }
}
