import 'dart:math' as math;

import 'package:app/core/designsystem/theme/app_gradients.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_page_content.dart';
import 'package:app/feature/auth/ui/widget/authenticated_body.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
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

    final currentSettings = settings.requireValue;
    final currentCard = card.requireValue;
    final sponsorsById = {for (final sponsor in sponsors.requireValue) sponsor.id: sponsor};
    // Stamps fill the road in the order they were collected; which sponsor
    // gave each one is deliberately not shown.
    final collected = (currentCard.stamps.entries.toList()..sort((a, b) => a.value.compareTo(b.value)))
        .map((entry) => sponsorsById[entry.key])
        .toList();

    return AppPageContent(
      maxWidth: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressCard(settings: currentSettings, card: currentCard, total: sponsorIds.requireValue.length),
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
          _SectionTitle(t.stampRally.thanksCardTitle),
          _ThanksCardTile(redeemedAt: currentCard.thanksCardRedeemedAt),
          const SizedBox(height: 24),
          _SectionTitle(t.stampRally.roadmapTitle),
          _Roadmap(
            nodes: _roadmapNodes(
              settings: currentSettings,
              card: currentCard,
              collected: collected,
              slots: sponsorIds.requireValue.length,
            ),
          ),
        ],
      ),
    );
  }
}

sealed class _RoadmapNode {
  const _RoadmapNode({required this.reached});

  final bool reached;
}

final class _StampNode extends _RoadmapNode {
  const _StampNode({required this.number, required this.sponsor, required super.reached, required this.isNext});

  final int number;

  /// The sponsor whose stamp fills this slot, for its artwork only.
  final Sponsor? sponsor;
  final bool isNext;
}

final class _CheckpointNode extends _RoadmapNode {
  const _CheckpointNode({required this.number, required this.required, required super.reached, this.redeemedAt});

  final int number;
  final int required;
  final DateTime? redeemedAt;
}

/// One slot per stamp sponsor, with each prize placed right after the stamp
/// that reaches it.
List<_RoadmapNode> _roadmapNodes({
  required StampRallySettings settings,
  required StampRallyCard card,
  required List<Sponsor?> collected,
  required int slots,
}) {
  final count = card.stampCount;
  final total = [slots, count, ...settings.checkpoints].reduce(math.max);
  return [
    for (var number = 1; number <= total; number++) ...[
      _StampNode(
        number: number,
        sponsor: number <= collected.length ? collected[number - 1] : null,
        reached: number <= count,
        isNext: number == count + 1,
      ),
      for (final (index, required) in settings.checkpoints.indexed)
        if (required == number)
          _CheckpointNode(
            number: index + 1,
            required: required,
            reached: count >= required,
            redeemedAt: card.rewardsRedeemedAt[index + 1],
          ),
    ],
  ];
}

// The stamp artwork is 4:3, so slots share its shape instead of cropping it.
const _stampWidth = 104.0;
const _stampHeight = 78.0;
const _stampRowHeight = 92.0;
const _checkpointRowHeight = 128.0;

/// Horizontal positions the stamps cycle through, as fractions of the width,
/// so the road winds left and right down the page.
const _zigzag = [0.2, 0.5, 0.8, 0.5];

class _Roadmap extends StatelessWidget {
  const _Roadmap({required this.nodes});

  final List<_RoadmapNode> nodes;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final centers = <Offset>[];
      var top = 0.0;
      var stampIndex = 0;
      for (final node in nodes) {
        final height = node is _CheckpointNode ? _checkpointRowHeight : _stampRowHeight;
        final x = node is _CheckpointNode ? 0.5 : _zigzag[stampIndex++ % _zigzag.length];
        centers.add(Offset(width * x, top + height / 2));
        top += height;
      }
      final colors = Theme.of(context).colorScheme;
      return SizedBox(
        height: top,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RoadPainter(
                  centers: centers,
                  reached: [for (final node in nodes) node.reached],
                  reachedColor: colors.primary,
                  pendingColor: colors.outlineVariant,
                ),
              ),
            ),
            for (final (index, node) in nodes.indexed)
              switch (node) {
                _StampNode() => Positioned(
                  left: centers[index].dx - _stampWidth / 2,
                  top: centers[index].dy - _stampHeight / 2,
                  child: _StampSlot(node: node),
                ),
                _CheckpointNode() => Positioned(
                  left: 0,
                  right: 0,
                  top: centers[index].dy - _checkpointRowHeight / 2 + 8,
                  height: _checkpointRowHeight - 16,
                  child: Center(child: _CheckpointMarker(node: node)),
                ),
              },
          ],
        ),
      );
    },
  );
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter({
    required this.centers,
    required this.reached,
    required this.reachedColor,
    required this.pendingColor,
  });

  final List<Offset> centers;
  final List<bool> reached;
  final Color reachedColor;
  final Color pendingColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var index = 1; index < centers.length; index++) {
      final from = centers[index - 1];
      final to = centers[index];
      final middle = (from.dy + to.dy) / 2;
      final segment = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx, middle, to.dx, middle, to.dx, to.dy);
      paint
        ..color = reached[index] ? reachedColor : pendingColor
        ..strokeWidth = reached[index] ? 6 : 4;
      canvas.drawPath(segment, paint);
    }
  }

  @override
  bool shouldRepaint(_RoadPainter oldDelegate) =>
      oldDelegate.centers != centers ||
      oldDelegate.reached != reached ||
      oldDelegate.reachedColor != reachedColor ||
      oldDelegate.pendingColor != pendingColor;
}

class _StampSlot extends StatelessWidget {
  const _StampSlot({required this.node});

  final _StampNode node;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sponsor = node.sponsor;
    final number = Center(
      child: Text(
        '${node.number}',
        style: theme.textTheme.titleMedium?.copyWith(
          color: node.isNext ? colors.primary : colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final collectedMark = Icon(Icons.approval, size: 36, color: colors.onPrimaryContainer);
    final radius = BorderRadius.circular(16);
    return Semantics(
      label: t.stampRally.stampSlotSemantic(
        n: node.number,
        status: node.reached ? t.stampRally.acquired : t.stampRally.notAcquired,
      ),
      child: ExcludeSemantics(
        child: Container(
          width: _stampWidth,
          height: _stampHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: node.reached ? colors.primaryContainer : colors.surfaceContainerHighest,
            boxShadow: node.reached
                ? [BoxShadow(color: colors.shadow.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          // Drawn in front so the artwork does not cover the frame.
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: node.reached || node.isNext ? colors.primary : colors.outlineVariant,
              width: node.reached ? 3 : 2,
            ),
          ),
          child: !node.reached
              ? number
              : sponsor == null
              ? collectedMark
              : StampImage(sponsor: sponsor, fit: BoxFit.cover, fallback: collectedMark),
        ),
      ),
    );
  }
}

class _CheckpointMarker extends StatelessWidget {
  const _CheckpointMarker({required this.node});

  final _CheckpointNode node;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final redeemedAt = node.redeemedAt;
    final (background, foreground, icon, status) = redeemedAt != null
        ? (
            colors.secondaryContainer,
            colors.onSecondaryContainer,
            Icons.check_circle,
            t.stampRally.checkpointRedeemed(date: formatStampRallyTime(context, redeemedAt)),
          )
        : node.reached
        ? (colors.primaryContainer, colors.onPrimaryContainer, Icons.redeem, t.stampRally.checkpointAchieved)
        : (colors.surfaceContainerHigh, colors.onSurfaceVariant, Icons.lock_outline, t.stampRally.checkpointLocked);
    return Semantics(
      container: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: node.reached ? colors.primary : colors.outlineVariant, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: 8),
                Text(
                  t.stampRally.checkpointLabel(number: node.number, required: node.required),
                  style: theme.textTheme.titleMedium?.copyWith(color: foreground, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(status, style: theme.textTheme.labelLarge?.copyWith(color: foreground)),
          ],
        ),
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

class _ThanksCardTile extends StatelessWidget {
  const _ThanksCardTile({required this.redeemedAt});

  final DateTime? redeemedAt;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final redeemed = redeemedAt;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(redeemed == null ? Icons.mail_outline : Icons.mark_email_read_outlined),
        title: Text(t.stampRally.thanksCardDescription),
        trailing: Text(
          redeemed == null
              ? t.stampRally.thanksCardNotRedeemed
              : t.stampRally.thanksCardRedeemed(date: formatStampRallyTime(context, redeemed)),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}

/// The stamp artwork for [sponsor], bundled under its website slug.
class StampImage extends StatelessWidget {
  const StampImage({required this.sponsor, required this.fallback, this.fit = BoxFit.contain, super.key});

  final Sponsor sponsor;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.asset(
    'res/assets/stamps/${sponsor.slug}.webp',
    fit: fit,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => fallback,
  );
}
