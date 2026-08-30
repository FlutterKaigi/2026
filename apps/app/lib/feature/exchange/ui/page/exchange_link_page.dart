import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/exchange_scan_outcome.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository_provider.dart';
import 'package:app/feature/profile/data/provider/user_profile_provider.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// `/x/:token` — Universal Link / App Link (and plain web link) landing page
/// for a scanned or shared profile-exchange QR payload
/// (`https://2026.flutterkaigi.jp/x/<token>`, see `exchange_link.dart`).
///
/// Reached only when the OS actually hands the link to the app (Associated
/// Domains on iOS, an `autoVerify` intent filter on Android — see
/// `ios/Runner/Runner.entitlements` and
/// `android/app/src/main/AndroidManifest.xml`) or when a user follows the
/// link inside the app itself (e.g. tapping it in a chat app that opens an
/// in-app browser backed by this same Flutter app). A browser with the app
/// not installed lands on the website's static `/x/` fallback page instead
/// (`apps/website`), which never reaches this route.
///
/// Signed-out or profile-less visitors get the same prompts as
/// [ExchangeHomeRoute] rather than an error, since arriving here mid-onboarding
/// (e.g. a fresh install that opened the link before signing in) is expected.
class ExchangeLinkPage extends HookConsumerWidget {
  const ExchangeLinkPage({required this.token, super.key});

  /// The raw path segment from the URL — a bare `v1.<uid>.<exp>.<sig>` token,
  /// never the full URL. go_router has already stripped the `/x/` prefix.
  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final user = ref.watch(authStateChangesProvider).value;
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.exchange.link.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: user == null
          ? _LinkPrompt(
              icon: Icons.qr_code_2_outlined,
              title: t.exchange.link.signInRequired,
              body: null,
              action: FilledButton(
                onPressed: () => const AccountRoute().go(context),
                child: Text(t.exchange.link.signInAction),
              ),
            )
          : switch (profileState) {
              AsyncData(value: null) => _LinkPrompt(
                icon: Icons.person_add_alt_outlined,
                title: t.exchange.link.profileRequiredTitle,
                body: t.exchange.link.profileRequiredBody,
                action: FilledButton(
                  onPressed: () => const ProfileEditRoute().push<void>(context),
                  child: Text(t.exchange.link.profileRequiredAction),
                ),
              ),
              AsyncData() => _ExchangeLinkBody(token: token, user: user),
              AsyncError(:final error) => AppErrorView(
                error: error,
                onRetry: () => ref.invalidate(userProfileProvider),
              ),
              AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
            },
    );
  }
}

/// Same centered icon/title/body/action layout as `exchange_home_page.dart`'s
/// private `_CenteredPrompt`. Kept as a separate (small) copy rather than
/// extracting a shared widget, so this page stays self-contained and PR2's
/// `exchange_home_page.dart` stays untouched.
class _LinkPrompt extends StatelessWidget {
  const _LinkPrompt({required this.icon, required this.title, required this.body, required this.action});

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

/// Runs [handleScannedExchangeToken] once for a signed-in user with a
/// profile, then shows the resulting message with a way back into the app.
class _ExchangeLinkBody extends HookConsumerWidget {
  const _ExchangeLinkBody({required this.token, required this.user});

  final String token;
  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final repository = ref.watch(profileExchangeRepositoryProvider);
    final outcome = useState<ExchangeScanOutcome?>(null);

    useEffect(() {
      var cancelled = false;
      unawaited(() async {
        final result = await handleScannedExchangeToken(raw: token, currentUid: user.uid, repository: repository);
        if (!cancelled) {
          outcome.value = result;
        }
      }());
      return () => cancelled = true;
      // Only re-run if the link or the signed-in user actually changes; the
      // repository instance is stable for the provider's lifetime.
    }, [token, user.uid]);

    final value = outcome.value;
    if (value == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(height: 16),
            Text(t.exchange.link.processing),
          ],
        ),
      );
    }
    return _OutcomeView(outcome: value);
  }
}

class _OutcomeView extends StatelessWidget {
  const _OutcomeView({required this.outcome});

  final ExchangeScanOutcome outcome;

  bool get _canViewList => switch (outcome.kind) {
    ExchangeScanOutcomeKind.success ||
    ExchangeScanOutcomeKind.duplicate ||
    ExchangeScanOutcomeKind.offlinePending => true,
    ExchangeScanOutcomeKind.selfScan ||
    ExchangeScanOutcomeKind.malformed ||
    ExchangeScanOutcomeKind.expired ||
    ExchangeScanOutcomeKind.error => false,
  };

  IconData get _icon => switch (outcome.kind) {
    ExchangeScanOutcomeKind.success => Icons.check_circle_outline,
    ExchangeScanOutcomeKind.duplicate || ExchangeScanOutcomeKind.offlinePending => Icons.info_outline,
    ExchangeScanOutcomeKind.selfScan ||
    ExchangeScanOutcomeKind.malformed ||
    ExchangeScanOutcomeKind.expired => Icons.warning_amber_outlined,
    ExchangeScanOutcomeKind.error => Icons.error_outline,
  };

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                exchangeScanOutcomeMessage(t, outcome),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              if (_canViewList) ...[
                FilledButton(
                  onPressed: () => const ExchangeListRoute().go(context),
                  child: Text(t.exchange.link.viewListAction),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: () => const EventInfoRoute().go(context),
                child: Text(t.exchange.link.doneAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
