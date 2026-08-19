import 'package:app/core/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// Legal trademark notices shown below content that may include sponsor logos.
class TrademarkFooterWidget extends StatelessWidget {
  const TrademarkFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notices = [
      t.trademarks.flutterAffiliation,
      t.trademarks.flutterNameAndLogo,
      t.trademarks.revComm,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: MergeSemantics(
              child: Column(
                children: [
                  for (final (index, notice) in notices.indexed) ...[
                    Text(
                      notice,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.75,
                      ),
                    ),
                    if (index != notices.length - 1) const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
