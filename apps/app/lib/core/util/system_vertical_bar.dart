import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Channel to the Runner, which reports `UITraitCollection.verticalBarEdge`
/// (iOS 27.1) and calls `edgeChanged` when it changes.
const verticalBarEdgeChannel = MethodChannel('jp.flutterkaigi.conf2026/vertical_bar_edge');

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

class _SystemVerticalBarScopeState extends State<SystemVerticalBarScope> {
  bool? _usesVerticalBar;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    verticalBarEdgeChannel.setMethodCallHandler(_handleCall);
    unawaited(_fetch());
  }

  @override
  void dispose() {
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
