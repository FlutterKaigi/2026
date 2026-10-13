import 'dart:async';

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_page_content.dart';
import 'package:app/feature/auth/ui/widget/authenticated_body.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:app/feature/stamp_rally/data/stamp_rally_provider.dart';
import 'package:app/feature/stamp_rally/ui/page/stamp_rally_page.dart';
import 'package:data/data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Opens `<app origin>/s/<token>`, from the OS camera as a Universal Link /
/// App Link, from the web app, or from the in-app scanner, and shows what the
/// server did with the code. Staff read the prize result off this screen.
class StampRallyLinkPage extends StatelessWidget {
  const StampRallyLinkPage({required this.token, super.key});

  final String token;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.stampRally.resultTitle)),
      body: !isStampRallyToken(token)
          ? _ResultMessage(icon: Icons.link_off, title: t.stampRally.invalidTitle, body: t.stampRally.invalidBody)
          : AuthenticatedBody(
              signedOut: _PendingSignIn(token: token),
              // A second link opened while a result is shown keeps this route,
              // so the token-derived key makes it scan again.
              builder: (uid) => _ScanResult(key: ValueKey(token), token: token),
            ),
    );
  }
}

/// Queues the token so `AccountPage` can finish it if the visitor signs in
/// from somewhere other than this page.
class _PendingSignIn extends HookConsumerWidget {
  const _PendingSignIn({required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      // Riverpod disallows modifying a provider from a widget life-cycle callback.
      unawaited(Future.microtask(() => ref.read(pendingStampRallyTokenProvider.notifier).set(null, token)));
      return null;
    }, [token]);
    final t = Translations.of(context);
    return AppPageContent(
      maxWidth: signInCardMaxWidth,
      padding: const EdgeInsets.all(24),
      centerVertically: true,
      child: SignInCard(title: t.auth.signIn.required, description: t.stampRally.signInRequired),
    );
  }
}

class _ScanResult extends HookConsumerWidget {
  const _ScanResult({required this.token, super.key});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final attempt = useState(0);
    final result = useState<AsyncValue<StampRallyScanResult>>(const AsyncLoading());

    useEffect(() {
      result.value = const AsyncLoading();
      final pending = ref.read(pendingStampRallyTokenProvider.notifier);
      final repository = ref.read(stampRallyRepositoryProvider);
      final talker = ref.read(talkerProvider);
      Future<void> scan() async {
        pending.clearIfCurrent(token);
        try {
          final value = await repository.scan(token);
          if (context.mounted) {
            result.value = AsyncData(value);
          }
        } on Exception catch (error, stackTrace) {
          talker.handle(error, stackTrace);
          if (context.mounted) {
            result.value = AsyncError(error, stackTrace);
          }
        }
      }

      unawaited(Future.microtask(scan));
      return null;
    }, [attempt.value]);

    return switch (result.value) {
      AsyncData(:final value) => switch (value) {
        StampRallyStampResult() => _StampResultView(result: value),
        StampRallyRewardResult() => _RewardResultView(result: value),
        StampRallyThanksCardResult() => _ResultMessage(
          icon: value.alreadyRedeemed ? Icons.mark_email_read_outlined : Icons.mail_outline,
          title: value.alreadyRedeemed ? t.stampRally.thanksCardAlreadyTitle : t.stampRally.thanksCardResultTitle,
          body: t.stampRally.thanksCardResultAt(date: formatStampRallyTime(context, value.redeemedAt)),
          emphasized: !value.alreadyRedeemed,
          staffNote: true,
        ),
      },
      AsyncError(:final error) => _errorView(t, error, onRetry: () => attempt.value++),
      _ => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(height: 16),
            Text(t.stampRally.processing),
          ],
        ),
      ),
    };
  }

  Widget _errorView(Translations t, Object error, {required VoidCallback onRetry}) {
    final code = error is FirebaseException ? error.code : null;
    return switch (code) {
      'not-found' || 'invalid-argument' => _ResultMessage(
        icon: Icons.link_off,
        title: t.stampRally.invalidTitle,
        body: t.stampRally.invalidBody,
      ),
      'failed-precondition' => _ResultMessage(
        icon: Icons.event_busy_outlined,
        title: t.stampRally.closedTitle,
        body: t.stampRally.closed,
      ),
      'unauthenticated' => _ResultMessage(icon: Icons.lock_outline, title: t.stampRally.sessionExpired),
      'permission-denied' => _ResultMessage(icon: Icons.block, title: t.stampRally.permissionDenied),
      'unavailable' || 'deadline-exceeded' || 'network-request-failed' || 'aborted' => _ResultMessage(
        icon: Icons.wifi_off,
        title: t.stampRally.networkError,
        onRetry: onRetry,
      ),
      _ => _ResultMessage(icon: Icons.error_outline, title: t.stampRally.failed, onRetry: onRetry),
    };
  }
}

class _StampResultView extends ConsumerWidget {
  const _StampResultView({required this.result});

  final StampRallyStampResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final sponsor = ref
        .watch(sponsorListProvider)
        .value
        ?.where((sponsor) => sponsor.id == result.sponsorId)
        .firstOrNull;
    return _ResultMessage(
      icon: result.alreadyAcquired ? Icons.verified_outlined : Icons.verified,
      artwork: sponsor == null ? null : StampImage(sponsor: sponsor, fallback: const SizedBox.shrink()),
      title: result.alreadyAcquired ? t.stampRally.stampAlreadyTitle : t.stampRally.stampAcquiredTitle,
      subtitle: sponsor?.name.resolve(Localizations.localeOf(context)),
      body: [
        for (final number in result.newCheckpoints) t.stampRally.checkpointReached(number: number),
      ].join('\n'),
      emphasized: result.newCheckpoints.isNotEmpty,
    );
  }
}

class _RewardResultView extends StatelessWidget {
  const _RewardResultView({required this.result});

  final StampRallyRewardResult result;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final redeemed = result.redeemedCheckpoints;
    final history = result.rewardsRedeemedAt.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return _ResultMessage(
      icon: redeemed.isEmpty ? Icons.inventory_2_outlined : Icons.redeem,
      title: redeemed.isEmpty
          ? t.stampRally.rewardNoneTitle
          : t.stampRally.rewardRedeemedTitle(numbers: redeemed.map((number) => '#$number').join(', ')),
      body: [
        if (redeemed.isEmpty) t.stampRally.rewardNoneBody(n: result.stampCount),
        for (final MapEntry(:key, :value) in history)
          t.stampRally.rewardRedeemedAt(number: key, date: formatStampRallyTime(context, value)),
      ].join('\n'),
      emphasized: redeemed.isNotEmpty,
      staffNote: true,
    );
  }
}

class _ResultMessage extends StatelessWidget {
  const _ResultMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.body,
    this.artwork,
    this.emphasized = false,
    this.staffNote = false,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? body;
  final Widget? artwork;
  final bool emphasized;
  final bool staffNote;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AppPageContent(
      maxWidth: 480,
      padding: const EdgeInsets.all(24),
      centerVertically: true,
      child: Card.outlined(
        margin: EdgeInsets.zero,
        color: emphasized ? colors.primaryContainer : null,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (artwork case final artwork?)
                AspectRatio(aspectRatio: 4 / 3, child: artwork)
              else
                Icon(icon, size: 56, color: emphasized ? colors.onPrimaryContainer : colors.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (subtitle case final subtitle?) ...[
                const SizedBox(height: 4),
                Text(subtitle, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              ],
              if (body case final body? when body.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(body, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              ],
              if (staffNote) ...[
                const SizedBox(height: 12),
                Text(
                  t.stampRally.rewardStaffNote,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 24),
              if (onRetry case final onRetry?) ...[
                FilledButton(onPressed: onRetry, child: Text(t.stampRally.retry)),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: () => const StampRallyRoute().go(context),
                child: Text(t.stampRally.viewCard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
