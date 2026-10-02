import 'package:app/core/designsystem/theme/app_gradients.dart';
import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_page_content.dart';
import 'package:app/feature/auth/ui/widget/authenticated_body.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:app/feature/sponsor/ui/widget/sponsor_logo_card_widget.dart';
import 'package:app/feature/stamp_rally/data/stamp_rally_provider.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

/// Collected stamps, prize checkpoints and the thanks card for the signed-in attendee.
class StampRallyPage extends StatelessWidget {
  const StampRallyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.stampRally.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: AuthenticatedBody(
        signedOut: AppPageContent(
          maxWidth: signInCardMaxWidth,
          padding: const EdgeInsets.all(24),
          centerVertically: true,
          child: SignInCard(title: t.auth.signIn.required, description: t.stampRally.signInRequired),
        ),
        builder: (uid) => _StampRallyBody(uid: uid),
      ),
    );
  }
}

/// Formats a redemption time for staff to compare against the clock.
String formatStampRallyTime(BuildContext context, DateTime time) =>
    DateFormat.Md(Translations.of(context).$meta.locale.languageCode).add_Hm().format(time.toLocal());

class _StampRallyBody extends ConsumerWidget {
  const _StampRallyBody({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final settings = ref.watch(stampRallySettingsProvider);
    final sponsorIds = ref.watch(stampRallySponsorIdsProvider);
    final card = ref.watch(stampRallyCardProvider(uid));
    final sponsors = ref.watch(sponsorListProvider);

    void retry() {
      ref
        ..invalidate(stampRallySettingsProvider)
        ..invalidate(stampRallySponsorIdsProvider)
        ..invalidate(stampRallyCardProvider(uid))
        ..invalidate(sponsorListProvider);
    }

    final values = [settings, sponsorIds, card, sponsors];
    if (values.firstWhere((value) => value.hasError, orElse: () => const AsyncLoading()) case AsyncError(
      :final error,
    )) {
      return AppErrorView(error: error, onRetry: retry);
    }
    if (values.any((value) => !value.hasValue)) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final ids = sponsorIds.requireValue;
    final targets = [
      for (final group in buildSponsorWallData(sponsors.requireValue).groups)
        for (final sponsor in group.sponsors)
          if (ids.contains(sponsor.id)) sponsor,
    ];
    final currentSettings = settings.requireValue;
    final currentCard = card.requireValue;

    return AppPageContent(
      maxWidth: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressCard(settings: currentSettings, card: currentCard, total: ids.length),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => const StampRallyScanRoute().push<void>(context),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(t.stampRally.scanButton),
          ),
          if (!currentSettings.isOpen) ...[
            const SizedBox(height: 12),
            _Notice(text: t.stampRally.closed),
          ],
          const SizedBox(height: 24),
          _SectionTitle(t.stampRally.checkpointsTitle),
          for (final (index, required) in currentSettings.checkpoints.indexed)
            _CheckpointTile(
              number: index + 1,
              required: required,
              achieved: currentCard.stampCount >= required,
              redeemedAt: currentCard.rewardsRedeemedAt[index + 1],
            ),
          const SizedBox(height: 16),
          _SectionTitle(t.stampRally.thanksCardTitle),
          _ThanksCardTile(redeemedAt: currentCard.thanksCardRedeemedAt),
          const SizedBox(height: 24),
          _SectionTitle(t.stampRally.sponsorsTitle),
          if (targets.isEmpty)
            Text(t.stampRally.sponsorsEmpty)
          else
            GridView.extent(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
              children: [
                for (final sponsor in targets)
                  _SponsorStamp(sponsor: sponsor, acquired: currentCard.stamps.containsKey(sponsor.id)),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.settings, required this.card, required this.total});

  final StampRallySettings settings;
  final StampRallyCard card;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final count = card.stampCount;
    final next = settings.checkpoints.indexed.where((entry) => entry.$2 > count).firstOrNull;
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.brand),
        // Keep white text readable over the magenta end of the artwork.
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.stampRally.stampCount(n: count, total: total),
                  semanticsLabel: t.stampRally.stampCountSemantic(n: count, total: total),
                  style: theme.textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  next == null
                      ? t.stampRally.allCheckpoints
                      : t.stampRally.nextCheckpoint(n: next.$2 - count, number: next.$1 + 1),
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  t.stampRally.description,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.tertiaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colors.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: TextStyle(color: colors.onTertiaryContainer)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
    ),
  );
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.icon, required this.title, required this.status, required this.highlighted});

  final IconData icon;
  final String title;
  final String status;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      color: highlighted ? colors.primaryContainer : null,
      child: ListTile(
        leading: Icon(icon, color: highlighted ? colors.onPrimaryContainer : colors.onSurfaceVariant),
        title: Text(title),
        trailing: Text(status, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}

class _CheckpointTile extends StatelessWidget {
  const _CheckpointTile({required this.number, required this.required, required this.achieved, this.redeemedAt});

  final int number;
  final int required;
  final bool achieved;
  final DateTime? redeemedAt;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final redeemed = redeemedAt;
    return _StatusTile(
      icon: redeemed != null
          ? Icons.check_circle
          : achieved
          ? Icons.redeem
          : Icons.lock_outline,
      title: t.stampRally.checkpointLabel(number: number, required: required),
      status: redeemed != null
          ? t.stampRally.checkpointRedeemed(date: formatStampRallyTime(context, redeemed))
          : achieved
          ? t.stampRally.checkpointAchieved
          : t.stampRally.checkpointLocked,
      highlighted: achieved && redeemed == null,
    );
  }
}

class _ThanksCardTile extends StatelessWidget {
  const _ThanksCardTile({required this.redeemedAt});

  final DateTime? redeemedAt;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final redeemed = redeemedAt;
    return _StatusTile(
      icon: redeemed == null ? Icons.mail_outline : Icons.mark_email_read_outlined,
      title: t.stampRally.thanksCardDescription,
      status: redeemed == null
          ? t.stampRally.thanksCardNotRedeemed
          : t.stampRally.thanksCardRedeemed(date: formatStampRallyTime(context, redeemed)),
      highlighted: false,
    );
  }
}

/// The stamp artwork for [sponsor], bundled under its website slug.
class StampImage extends StatelessWidget {
  const StampImage({required this.sponsor, required this.fallback, super.key});

  final Sponsor sponsor;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => Image.asset(
    'res/assets/stamps/${sponsor.slug}.webp',
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => fallback,
  );
}

class _SponsorStamp extends StatelessWidget {
  const _SponsorStamp({required this.sponsor, required this.acquired});

  final Sponsor sponsor;
  final bool acquired;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final name = sponsor.name.resolve(Localizations.localeOf(context)).trim();
    final logo = LayoutBuilder(
      builder: (context, constraints) => ColoredBox(
        color: Colors.white,
        child: SponsorLogoImage(sponsor: sponsor, name: name, side: constraints.biggest.shortestSide),
      ),
    );
    return Semantics(
      container: true,
      label: t.stampRally.sponsorSemantic(
        name: name,
        status: acquired ? t.stampRally.acquired : t.stampRally.notAcquired,
      ),
      child: ExcludeSemantics(
        child: Card.outlined(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          color: acquired ? theme.colorScheme.primaryContainer : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (acquired) StampImage(sponsor: sponsor, fallback: logo) else Opacity(opacity: 0.4, child: logo),
                    if (acquired)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.verified, color: theme.colorScheme.primary),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
