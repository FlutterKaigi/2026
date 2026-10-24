import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Side of the screen where iOS stacks its system bars into a vertical bar.
///
/// iPhone Duo moves the status bar into a column along one side of the
/// display: on the outer display, and on the inner display in landscape.
/// Flutter only sees that column as a safe area inset on one side with no top
/// inset, so that is how it is detected. Landscape iPhones report insets on
/// both sides and are not matched.
enum VerticalBarEdge {
  left,
  right;

  /// Returns the edge holding the vertical bar for the given safe area
  /// [padding], or `null` when the system bars are laid out horizontally.
  static VerticalBarEdge? fromPadding(EdgeInsets padding) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS || padding.top > 0) {
      return null;
    }
    return switch ((padding.left > 0, padding.right > 0)) {
      (true, false) => VerticalBarEdge.left,
      (false, true) => VerticalBarEdge.right,
      _ => null,
    };
  }

  /// Returns the edge holding the vertical bar in [context], if any.
  static VerticalBarEdge? of(BuildContext context) => fromPadding(MediaQuery.paddingOf(context));
}
