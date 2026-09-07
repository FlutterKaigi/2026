import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Scales [child] down while it is being pressed.
class PressScaleEffectWidget extends StatefulWidget {
  const PressScaleEffectWidget({
    required this.child,
    this.onTap,
    this.enabled = true,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 90),
    this.reverseDuration = const Duration(milliseconds: 140),
    this.curve = Curves.easeOutCubic,
    this.reverseCurve = Curves.easeOutCubic,
    this.behavior = HitTestBehavior.opaque,
    super.key,
  }) : assert(
         pressedScale > 0 && pressedScale <= 1,
         'pressedScale must be greater than 0 and less than or equal to 1.',
       );

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double pressedScale;
  final Duration duration;
  final Duration reverseDuration;
  final Curve curve;
  final Curve reverseCurve;
  final HitTestBehavior behavior;

  @override
  State<PressScaleEffectWidget> createState() => _PressScaleEffectWidgetState();
}

class _PressScaleEffectWidgetState extends State<PressScaleEffectWidget> {
  Timer? _keyboardFeedbackTimer;
  bool _isPressed = false;

  bool get _canTap => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (!_canTap || _isPressed == value) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  void _handleTap() {
    if (!_canTap) {
      return;
    }
    widget.onTap?.call();
  }

  Object? _handleKeyboardActivate(ActivateIntent intent) {
    if (!_canTap) {
      return null;
    }
    _setPressed(true);
    _keyboardFeedbackTimer?.cancel();
    _keyboardFeedbackTimer = Timer(widget.duration, () {
      if (!mounted) {
        return;
      }
      _setPressed(false);
      _handleTap();
    });
    return null;
  }

  @override
  void dispose() {
    _keyboardFeedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? widget.pressedScale : 1.0;
    return FocusableActionDetector(
      enabled: _canTap,
      mouseCursor: _canTap ? SystemMouseCursors.click : MouseCursor.defer,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: _handleKeyboardActivate,
        ),
      },
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _canTap ? (_) => _setPressed(true) : null,
        onTapUp: _canTap ? (_) => _setPressed(false) : null,
        onTapCancel: _canTap ? () => _setPressed(false) : null,
        onTap: _canTap ? _handleTap : null,
        child: AnimatedScale(
          scale: scale,
          duration: _isPressed ? widget.duration : widget.reverseDuration,
          curve: _isPressed ? widget.curve : widget.reverseCurve,
          child: widget.child,
        ),
      ),
    );
  }
}
