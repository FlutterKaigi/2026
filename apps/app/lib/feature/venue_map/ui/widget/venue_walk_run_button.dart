import 'package:flutter/material.dart';

class VenueWalkRunButton extends StatefulWidget {
  const VenueWalkRunButton({required this.pressed, required this.onChanged, super.key});

  final bool pressed;
  final ValueChanged<bool> onChanged;

  @override
  State<VenueWalkRunButton> createState() => _VenueWalkRunButtonState();
}

class _VenueWalkRunButtonState extends State<VenueWalkRunButton> {
  int? pointer;

  @override
  void didUpdateWidget(VenueWalkRunButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Stop/reset/backgrounding also cancels a held pointer.
    if (!widget.pressed) {
      pointer = null;
    }
  }

  void release(int id) {
    if (pointer == id) {
      pointer = null;
      widget.onChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      button: true,
      label: '走る',
      value: widget.pressed ? '走る速度' : '歩く速度',
      hint: '押している間だけ走ります。離すと歩きます。キーボードではShiftキーを使います。',
      child: ExcludeSemantics(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (pointer == null) {
              pointer = event.pointer;
              widget.onChanged(true);
            }
          },
          onPointerUp: (event) => release(event.pointer),
          onPointerCancel: (event) => release(event.pointer),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.pressed ? colors.primary : colors.surface.withValues(alpha: .95),
              shape: BoxShape.circle,
              border: Border.all(color: widget.pressed ? colors.primary : colors.outlineVariant),
            ),
            child: Icon(
              Icons.directions_run,
              size: 30,
              color: widget.pressed ? colors.onPrimary : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
