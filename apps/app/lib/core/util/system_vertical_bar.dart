import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Channel to the Runner, which reports `UITraitCollection.verticalBarEdge`
/// (iOS 27.1) and calls `edgeChanged` when it changes.
const verticalBarEdgeChannel = MethodChannel('jp.flutterkaigi.conf2026/vertical_bar_edge');

/// The longest UIKit's `unspecified` waits for the view to be resized.
///
/// When the open iPhone Duo turns from landscape to portrait, UIKit says the
/// vertical bar is gone about 150 ms before it resizes the view. Taking that
/// answer at once lays out the landscape frame without the bar for a moment,
/// in the middle of the rotation. So the answer waits for the next resize,
/// and no longer than this when none comes.
const verticalBarRemovalTimeout = Duration(milliseconds: 500);

/// Tells the widgets below whether UIKit places a vertical bar (iPhone Duo).
///
/// `VerticalBarEdge` guesses the vertical bar from the shape of the safe area.
/// UIKit answers `unspecified` on devices and in states that never use one,
/// so that answer guards the guess against shapes it was not written for,
/// such as iPad windows. Until UIKit answers, and where it cannot (before iOS
/// 27.1, on the web and on Android), the guess stands alone.
class SystemVerticalBarScope extends StatefulWidget {
  const SystemVerticalBarScope({required this.child, super.key});

  final Widget child;

  /// Returns `false` when UIKit says there is no vertical bar, `true` when it
  /// names an edge for one, and `null` when it has not said.
  static bool? usesVerticalBarOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SystemVerticalBar>()?.usesVerticalBar;

  @override
  State<SystemVerticalBarScope> createState() => _SystemVerticalBarScopeState();
}

class _SystemVerticalBarScopeState extends State<SystemVerticalBarScope> with WidgetsBindingObserver {
  bool? _usesVerticalBar;
  Timer? _pendingRemoval;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    verticalBarEdgeChannel.setMethodCallHandler(_handleCall);
    unawaited(_fetch());
  }

  @override
  void didChangeMetrics() {
    if (_pendingRemoval != null) {
      _apply(false);
    }
  }

  @override
  void dispose() {
    _pendingRemoval?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    verticalBarEdgeChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      _update(await verticalBarEdgeChannel.invokeMethod<String>('edge'));
    } on MissingPluginException {
      // Not built with the Runner's channel, as in widget tests.
    } on PlatformException {
      // Keep relying on the safe area alone.
    }
  }

  Future<void> _handleCall(MethodCall call) async {
    if (call.method == 'edgeChanged') {
      _update(call.arguments as String?);
    }
  }

  void _update(String? edge) {
    final usesVerticalBar = edge == null ? null : edge != 'unspecified';
    // UIKit can say the bar is gone before it resizes the view, while the
    // safe area still makes room for it. Taking that at once would lay out
    // the old size without the bar, so it waits for the resize. The first
    // answer, and any that allows a bar, applies at once.
    if (usesVerticalBar == false && _usesVerticalBar == true) {
      _pendingRemoval ??= Timer(verticalBarRemovalTimeout, () => _apply(false));
      return;
    }
    _apply(usesVerticalBar);
  }

  void _apply(bool? usesVerticalBar) {
    _pendingRemoval?.cancel();
    _pendingRemoval = null;
    if (mounted && usesVerticalBar != _usesVerticalBar) {
      setState(() => _usesVerticalBar = usesVerticalBar);
    }
  }

  @override
  Widget build(BuildContext context) => _SystemVerticalBar(usesVerticalBar: _usesVerticalBar, child: widget.child);
}

class _SystemVerticalBar extends InheritedWidget {
  const _SystemVerticalBar({required this.usesVerticalBar, required super.child});

  final bool? usesVerticalBar;

  @override
  bool updateShouldNotify(_SystemVerticalBar oldWidget) => usesVerticalBar != oldWidget.usesVerticalBar;
}
