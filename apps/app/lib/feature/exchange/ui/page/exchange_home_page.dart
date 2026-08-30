import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/exchange_scan_outcome.dart';
import 'package:app/feature/exchange/data/provider/exchange_qr_token_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_list_provider.dart';
import 'package:app/feature/exchange/ui/widget/exchange_enter_code_sheet.dart';
import 'package:app/feature/exchange/ui/widget/exchange_qr_card_widget.dart';
import 'package:app/feature/exchange/ui/widget/exchange_show_code_sheet.dart';
import 'package:app/feature/profile/data/provider/user_profile_provider.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// `/account/exchange` — the signed-in user's own QR code, 6-digit code
/// fallback, and entry points to scanning and the exchanged-profile list.
class ExchangeHomePage extends HookConsumerWidget {
  const ExchangeHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final user = ref.watch(authStateChangesProvider).value;
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.exchange.home.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: user == null
          ? _SignInRequiredView(onSignIn: () => const AccountRoute().go(context))
          : switch (profileState) {
              AsyncData(value: null) => _ProfileRequiredView(
                onCreateProfile: () => const ProfileEditRoute().push<void>(context),
              ),
              AsyncData() => _ExchangeHomeBody(user: user),
              AsyncError(:final error) => AppErrorView(
                error: error,
                onRetry: () => ref.invalidate(userProfileProvider),
              ),
              AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
            },
    );
  }
}

class _SignInRequiredView extends StatelessWidget {
  const _SignInRequiredView({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return _CenteredPrompt(
      icon: Icons.qr_code_2_outlined,
      title: t.exchange.home.signInRequired,
      body: null,
      action: FilledButton(onPressed: onSignIn, child: Text(t.exchange.home.signInAction)),
    );
  }
}

class _ProfileRequiredView extends StatelessWidget {
  const _ProfileRequiredView({required this.onCreateProfile});

  final VoidCallback onCreateProfile;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return _CenteredPrompt(
      icon: Icons.person_add_alt_outlined,
      title: t.exchange.home.profileRequiredTitle,
      body: t.exchange.home.profileRequiredBody,
      action: FilledButton(onPressed: onCreateProfile, child: Text(t.exchange.home.profileRequiredAction)),
    );
  }
}

class _CenteredPrompt extends StatelessWidget {
  const _CenteredPrompt({required this.icon, required this.title, required this.body, required this.action});

  final IconData icon;
  final String title;
  final String? body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              if (body != null) ...[
                const SizedBox(height: 8),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 20),
              action,
            ],
          ),
        ),
      ),
    );
  }
}

class _ExchangeHomeBody extends HookConsumerWidget {
  const _ExchangeHomeBody({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final qrState = ref.watch(exchangeQrTokenProvider);
    final countState = ref.watch(profileExchangeCountProvider);

    Future<void> showMessage(String message) async {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    return AppScrollbar(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExchangeQrCardWidget(
                    state: qrState,
                    onRefresh: () => ref.read(exchangeQrTokenProvider.notifier).refresh(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      final outcome = await const ExchangeScanRoute().push<ExchangeScanOutcome>(context);
                      if (outcome != null) {
                        await showMessage(exchangeScanOutcomeMessage(t, outcome));
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(t.exchange.home.scanAction),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => showExchangeCodeSheet(context),
                          child: Text(t.exchange.home.showCodeAction),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final outcome = await showExchangeEnterCodeSheet(context);
                            if (outcome != null) {
                              await showMessage(exchangeScanOutcomeMessage(t, outcome));
                            }
                          },
                          child: Text(t.exchange.home.enterCodeAction),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card.outlined(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    semanticContainer: false,
                    child: ListTile(
                      minTileHeight: 56,
                      leading: const Icon(Icons.groups_outlined),
                      title: Text(t.exchange.home.listAction),
                      trailing: switch (countState) {
                        AsyncData(:final value) => Text('$value', style: Theme.of(context).textTheme.titleMedium),
                        _ => const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      },
                      onTap: () => const ExchangeListRoute().push<void>(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
