/// Width-based layout breakpoints following Material 3 window size classes.
enum WindowSize {
  compact,
  medium,
  expanded
  ;

  /// Returns the [WindowSize] matching the given [width] in logical pixels.
  factory WindowSize.fromWidth(double width) => switch (width) {
    >= 840 => WindowSize.expanded,
    >= 600 => WindowSize.medium,
    _ => WindowSize.compact,
  };
}
