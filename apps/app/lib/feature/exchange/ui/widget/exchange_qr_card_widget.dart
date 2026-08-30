import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/exchange/data/exchange_link.dart';
import 'package:app/feature/exchange/data/provider/exchange_qr_token_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The signed-in user's own exchange QR code, with an offline-cache badge and
/// a manual refresh action.
class ExchangeQrCardWidget extends StatelessWidget {
  const ExchangeQrCardWidget({required this.state, required this.onRefresh, super.key});

  final AsyncValue<ExchangeQrToken> state;
  final VoidCallback onRefresh;

  static const _qrSize = 220.0;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t.exchange.home.qrTitle, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: t.exchange.home.refreshQr,
                  onPressed: state.isLoading ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              t.exchange.home.qrDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            switch (state) {
              AsyncData(:final value) => Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: QrImageView(
                        data: buildExchangeQrUri(value.token).toString(),
                        size: _qrSize,
                        semanticsLabel: t.exchange.home.qrTitle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (value.isCached)
                    _StatusBadge(
                      icon: Icons.cloud_off,
                      label: t.exchange.home.qrOffline,
                      color: theme.colorScheme.error,
                    )
                  else
                    Text(
                      t.exchange.home.qrExpiresAt(
                        date: DateFormat.Md(locale.toLanguageTag()).add_Hm().format(value.expiresAt),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
              AsyncError() => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(t.exchange.home.qrLoadFailed, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: onRefresh, child: Text(t.error.retry)),
                  ],
                ),
              ),
              _ => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ),
    ],
  );
}
