import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/exchange/ui/widget/exchange_access_gate.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Own QR code and the entry points to scan another attendee's QR code or
/// view previously exchanged profiles.
class ExchangeHomePage extends ConsumerWidget {
  const ExchangeHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.exchange.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ExchangeAccessGate(builder: (context) => const _ExchangeHomeBody()),
    );
  }
}

class _ExchangeHomeBody extends ConsumerWidget {
  const _ExchangeHomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final tokenState = ref.watch(myExchangeTokenProvider);

    return AppScrollbar(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.exchange.qrDescription,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                switch (tokenState) {
                  AsyncData(:final value) => _QrCard(qrPayload: value.qrPayload, expiresAt: value.expiresAt),
                  AsyncError(:final error) => AppErrorView(
                    error: error,
                    onRetry: () => ref.read(myExchangeTokenProvider.notifier).refresh(),
                  ),
                  AsyncLoading() => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                },
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => const ExchangeScanRoute().push<void>(context),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(t.exchange.scanButton),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => const ExchangeListRoute().push<void>(context),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.people_outline),
                  label: Text(t.exchange.listButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.qrPayload, required this.expiresAt});

  final String qrPayload;
  final DateTime expiresAt;

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
            // A QR reader binarizes the image assuming dark modules on a
            // light background, so the code must stay white/black no matter
            // which app theme is active — following Card.outlined's dark
            // surface here would make the code fail to scan, not just be
            // hard to see. `padding` is drawn inside `backgroundColor` (see
            // qr_flutter's `_QrContentView`), so the package's own default
            // already gives the modules a quiet zone that sits on white;
            // it is restated explicitly rather than left implicit.
            // The rounded clip keeps the white square from reading as a
            // stray rectangle against the card's rounded corners.
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: QrImageView(
                data: qrPayload,
                size: 220,
                padding: const EdgeInsets.all(10),
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
                semanticsLabel: t.exchange.qrSemanticLabel,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.exchange.qrExpiresAt(date: DateFormat.yMd(locale.toString()).add_Hm().format(expiresAt.toLocal())),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
