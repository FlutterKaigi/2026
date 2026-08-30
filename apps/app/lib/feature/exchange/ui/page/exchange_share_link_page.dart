import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/exchange_scan_handler.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:app/feature/exchange/data/pending_exchange_resolver.dart';
import 'package:app/feature/exchange/data/provider/pending_exchange_token_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/exchange/ui/widget/exchange_access_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Opens `https://2026.flutterkaigi.jp/x/<token>` — a profile-exchange share
/// link, whether tapped as a Universal Link / App Link (cold or warm start)
/// or reached in-app.
///
/// Malformed and already-expired tokens are rejected here, before the
/// [ExchangeAccessGate], so opening a stale or garbled link never forces a
/// sign-in the link couldn't have honoured anyway. A well-formed, unexpired
/// token still needs a signed-in user with a profile to resolve — see
/// [_PendingShareLink].
class ExchangeShareLinkPage extends StatelessWidget {
  const ExchangeShareLinkPage({required this.token, super.key});

  final String token;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final scanned = parseScannedExchangeToken(token);

    return Scaffold(
      appBar: AppBar(title: Text(t.exchange.title)),
      body: switch (scanned) {
        null => _ShareLinkMessage(
          icon: Icons.link_off,
          title: t.exchange.shareLinkInvalidTitle,
          body: t.exchange.shareLinkInvalidBody,
        ),
        _ when isExchangeTokenExpired(token) => _ShareLinkMessage(
          icon: Icons.timer_off_outlined,
          title: t.exchange.shareLinkExpiredTitle,
          body: t.exchange.shareLinkExpiredBody,
        ),
        _ => _PendingShareLink(token: token),
      },
    );
  }
}

/// Queues [token] in `pendingExchangeTokenProvider` (so it survives a
/// sign-in / profile-creation detour — see the provider's doc comment) and
/// waits on the same [ExchangeAccessGate] every other exchange route uses.
class _PendingShareLink extends HookConsumerWidget {
  const _PendingShareLink({required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      // Deferred to a microtask: Riverpod disallows modifying a provider
      // synchronously from a widget life-cycle callback (`useEffect` runs as
      // one), since a listener further down the same build could otherwise
      // observe an inconsistent state mid-build.
      final uid = ref.read(authStateChangesProvider).value?.uid;
      unawaited(Future.microtask(() => ref.read(pendingExchangeTokenProvider.notifier).set(uid, token)));
      return null;
    }, [token]);

    final t = Translations.of(context);
    return ExchangeAccessGate(
      signInTitle: t.exchange.shareLinkSignInRequired,
      profileTitle: t.exchange.shareLinkProfileRequired,
      builder: (context) => _ShareLinkBody(token: token),
    );
  }
}

/// Resolves [token] against the now-confirmed signed-in, profile-having user
/// and renders the outcome. Runs at most once per page instance regardless
/// of rebuilds (the `useRef` guard), and clears the pending token it just
/// handled so `AccountPage`'s own listener (the fallback for a sign-in
/// detour that ends up back there instead of on this page) doesn't also
/// attempt it.
class _ShareLinkBody extends HookConsumerWidget {
  const _ShareLinkBody({required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(authStateChangesProvider).value?.uid;
    final started = useRef(false);
    final result = useState<PendingExchangeResult?>(null);

    useEffect(() {
      if (started.value || myUid == null) {
        return null;
      }
      started.value = true;

      Future<void> resolve() async {
        final resolved = await resolvePendingExchangeToken(
          token: token,
          myUid: myUid,
          repository: ref.read(profileExchangeRepositoryProvider),
        );
        ref.read(pendingExchangeTokenProvider.notifier).clearIfCurrent(myUid, token);
        if (resolved case PendingExchangeResolved(outcome: ExchangeCreateFailed(:final error, :final stackTrace))) {
          ref.read(talkerProvider).handle(error, stackTrace);
        }
        result.value = resolved;
      }

      unawaited(resolve());
      return null;
    }, [myUid]);

    final value = result.value;
    if (value == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    return _ShareLinkResultView(result: value);
  }
}

class _ShareLinkResultView extends StatelessWidget {
  const _ShareLinkResultView({required this.result});

  final PendingExchangeResult result;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return switch (result) {
      PendingExchangeInvalid() => _ShareLinkMessage(
        icon: Icons.link_off,
        title: t.exchange.shareLinkInvalidTitle,
        body: t.exchange.shareLinkInvalidBody,
      ),
      PendingExchangeExpired() => _ShareLinkMessage(
        icon: Icons.timer_off_outlined,
        title: t.exchange.shareLinkExpiredTitle,
        body: t.exchange.shareLinkExpiredBody,
      ),
      PendingExchangeSelf() => _ShareLinkMessage(
        icon: Icons.qr_code_2_outlined,
        title: t.exchange.shareLinkSelfTitle,
        body: t.exchange.shareLinkSelfBody,
      ),
      PendingExchangeResolved(:final outcome) => switch (outcome) {
        ExchangeCreated() => _ShareLinkMessage(
          icon: Icons.check_circle_outline,
          title: t.exchange.scanSucceeded,
          showsListAction: true,
        ),
        ExchangeAlreadyExists() => _ShareLinkMessage(
          icon: Icons.people_outline,
          title: t.exchange.scanAlreadyExists,
          showsListAction: true,
        ),
        ExchangeCreateFailed() => _ShareLinkMessage(
          icon: Icons.error_outline,
          title: t.exchange.scanFailed,
        ),
      },
    };
  }
}

class _ShareLinkMessage extends StatelessWidget {
  const _ShareLinkMessage({
    required this.icon,
    required this.title,
    this.body,
    this.showsListAction = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final bool showsListAction;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    return Center(
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
            if (body case final body?) ...[
              const SizedBox(height: 8),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            if (showsListAction) ...[
              FilledButton(
                onPressed: () => const ExchangeListRoute().go(context),
                child: Text(t.exchange.shareLinkViewList),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => const EventInfoRoute().go(context),
                child: Text(t.exchange.shareLinkGoHome),
              ),
            ] else
              FilledButton(
                onPressed: () => const EventInfoRoute().go(context),
                child: Text(t.exchange.shareLinkGoHome),
              ),
          ],
        ),
      ),
    );
  }
}
