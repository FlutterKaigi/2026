import 'package:app/core/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Number of digits in a Support LT registration code.
const supportLtCodeLength = 6;

/// Height of each digit box.
const _boxHeight = 56.0;

/// Six-digit registration code entry drawn as one box per digit.
///
/// A single transparent [TextFormField] lies over the boxes and receives taps,
/// typing and paste, so the boxes only mirror its text and focus.
class SupportLtCodeField extends HookWidget {
  const SupportLtCodeField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
    this.errorText,
    this.highlightsError = false,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  /// Message shown below the boxes; `null` hides it.
  final String? errorText;

  /// Whether the label and boxes use the error color, for errors about the
  /// entered code itself.
  final bool highlightsError;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final focusNode = useFocusNode();
    final hasFocus = useListenableSelector(focusNode, () => focusNode.hasFocus);
    final text = useValueListenable(controller).text;
    final activeIndex = enabled && hasFocus ? text.length.clamp(0, supportLtCodeLength - 1) : null;
    final labelColor = switch ((enabled, highlightsError)) {
      (false, _) => colorScheme.onSurface.withValues(alpha: 0.38),
      (true, true) => colorScheme.error,
      (true, false) => colorScheme.onSurfaceVariant,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 読み上げは入力欄のヒントで行うため、見出しは重ねて読ませない。
        ExcludeSemantics(
          child: Text(t.supportLt.codeLabel, style: theme.textTheme.labelLarge?.copyWith(color: labelColor)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _boxHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(
                child: Row(
                  children: [
                    for (var index = 0; index < supportLtCodeLength; index++) ...[
                      if (index > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _DigitBox(
                          digit: index < text.length ? text[index] : null,
                          isActive: index == activeIndex,
                          enabled: enabled,
                          highlightsError: highlightsError,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 入力と貼り付けは、マス目に重ねた 1 つの透明な入力欄が受け取る。
              DefaultSelectionStyle.merge(
                cursorColor: Colors.transparent,
                selectionColor: Colors.transparent,
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(supportLtCodeLength),
                  ],
                  showCursor: false,
                  style: const TextStyle(color: Colors.transparent),
                  decoration: InputDecoration.collapsed(
                    hintText: t.supportLt.codeLabel,
                    hintStyle: const TextStyle(color: Colors.transparent),
                  ),
                  onChanged: onChanged,
                  onFieldSubmitted: onSubmitted,
                ),
              ),
            ],
          ),
        ),
        if (errorText case final message?) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(message, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error)),
          ),
        ],
      ],
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.digit,
    required this.isActive,
    required this.enabled,
    required this.highlightsError,
  });

  final String? digit;

  /// Whether the next digit goes into this box while the field has focus.
  final bool isActive;
  final bool enabled;
  final bool highlightsError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final side = switch ((enabled, highlightsError, isActive)) {
      (false, _, _) => BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.12)),
      (true, true, _) => BorderSide(color: colorScheme.error),
      (true, false, true) => BorderSide(color: colorScheme.primary, width: 2),
      (true, false, false) => BorderSide(color: colorScheme.outline),
    };

    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: side),
      ),
      child: Center(
        child: switch (digit) {
          final value? => Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
          // 次に入力されるマスの目印(点滅はさせない)。
          null when isActive => SizedBox(width: 2, height: 28, child: ColoredBox(color: colorScheme.primary)),
          null => null,
        },
      ),
    );
  }
}
