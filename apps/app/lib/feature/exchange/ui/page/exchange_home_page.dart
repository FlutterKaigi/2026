import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/profile/data/provider/user_profile_provider.dart';
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
    final authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.exchange.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: switch (authState) {
        AsyncData(value: null) => _SignInPrompt(t: t),
        AsyncData() => const _ProfileGate(),
        AsyncError(:final error) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(authStateChangesProvider),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
      },
    );
  }
}

/// Waits for the signed-in user's profile before showing the QR code, since
/// exchange tokens are issued for a uid regardless of whether a profile
/// exists, but scanning them without a profile would join nothing meaningful.
class _ProfileGate extends ConsumerWidget {
  const _ProfileGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final profileState = ref.watch(userProfileProvider);

    return switch (profileState) {
      AsyncData(value: null) => _ProfilePrompt(t: t),
      AsyncData() => const _ExchangeHomeBody(),
      AsyncError(:final error) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(userProfileProvider),
      ),
      AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
    };
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
            QrImageView(
              data: qrPayload,
              size: 220,
              semanticsLabel: t.exchange.qrSemanticLabel,
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

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context) => _MessagePrompt(
    icon: Icons.qr_code_2_outlined,
    title: t.exchange.signInRequired,
    actionLabel: t.exchange.signInAction,
    onAction: () => const AccountRoute().go(context),
  );
}

class _ProfilePrompt extends StatelessWidget {
  const _ProfilePrompt({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context) => _MessagePrompt(
    icon: Icons.person_add_alt_1_outlined,
    title: t.exchange.profileRequired,
    actionLabel: t.exchange.profileRequiredAction,
    onAction: () => const ProfileEditRoute().push<void>(context),
  );
}

class _MessagePrompt extends StatelessWidget {
  const _MessagePrompt({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScrollbar(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
