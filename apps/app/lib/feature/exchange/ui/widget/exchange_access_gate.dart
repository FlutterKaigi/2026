import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/profile/data/provider/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Guards every `/account/exchange` route behind sign-in and a created
/// profile, showing [builder]'s content only once both are satisfied.
///
/// `ExchangeHomeRoute` is the only entry point the account tab links to, but
/// `ExchangeScanRoute` / `ExchangeListRoute` are independently reachable
/// (e.g. a deep link), so each route wraps its body in this gate rather than
/// relying on `ExchangeHomeRoute` having been visited first.
class ExchangeAccessGate extends ConsumerWidget {
  const ExchangeAccessGate({required this.builder, super.key});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final authState = ref.watch(authStateChangesProvider);

    return switch (authState) {
      AsyncData(value: null) => _SignInPrompt(t: t),
      AsyncData() => _ProfileGate(builder: builder),
      AsyncError(:final error) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(authStateChangesProvider),
      ),
      AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
    };
  }
}

/// Waits for the signed-in user's profile, since exchange tokens are issued
/// for a uid regardless of whether a profile exists, but scanning or viewing
/// exchanges without one would join or list nothing meaningful.
class _ProfileGate extends ConsumerWidget {
  const _ProfileGate({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final profileState = ref.watch(userProfileProvider);

    return switch (profileState) {
      AsyncData(value: null) => _ProfilePrompt(t: t),
      AsyncData() => builder(context),
      AsyncError(:final error) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(userProfileProvider),
      ),
      AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
    };
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
