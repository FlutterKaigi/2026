import 'package:app/core/constants/event_schedule.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/provider/clock.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_page_content.dart';
import 'package:app/feature/auth/ui/widget/authenticated_body.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/mission/data/mission_provider.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/sns_post/data/sns_post_provider.dart';
import 'package:app/feature/stamp_rally/data/stamp_rally_provider.dart';
import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
import 'package:app/feature/venue_events/ui/venue_event_feature.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show ProviderListenable;

/// Every venue activity of the event days in one place.
///
/// Signed out, it prompts for sign-in above a preview of the activities.
/// Signed in, it lists them with the attendee's status in each.
class VenueEventsPage extends StatelessWidget {
  const VenueEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.venueEvents.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: AuthenticatedBody(
        signedOut: const AppPageContent(maxWidth: 640, child: _SignedOutContent()),
        builder: (uid) => AppPageContent(maxWidth: 640, child: _SignedInContent(uid: uid)),
      ),
    );
  }
}

class _EventDayLabel extends ConsumerWidget {
  const _EventDayLabel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = switch (ref.watch(clockTickProvider)) {
      AsyncData(:final value) => value,
      _ => ref.watch(clockProvider)(),
    };
    final day = eventDayAt(now);
    if (day == null) {
      return const SizedBox.shrink();
    }
    final t = Translations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        switch (day) {
          EventDay.day1 => t.venueEvents.day1,
          EventDay.day2 => t.venueEvents.day2,
        },
        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// The preview tiles are not links. Every activity needs the account first,
/// which the sign-in card above asks for.
class _SignedOutContent extends StatelessWidget {
  const _SignedOutContent();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    const features = VenueEventFeature.signedOutPreview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _EventDayLabel(),
        SignInCard(
          title: t.venueEvents.signInTitle,
          description: t.venueEvents.signInDescription,
          showsBrandHeader: false,
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            t.venueEvents.previewHeading,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 8),
        // Rows of two rather than a fixed-aspect grid, so the tiles grow with
        // large text.
        for (var start = 0; start < features.length; start += 2) ...[
          if (start > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _PreviewTile(feature: features[start])),
                const SizedBox(width: 8),
                Expanded(
                  child: start + 1 < features.length
                      ? _PreviewTile(feature: features[start + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.feature});

  final VenueEventFeature feature;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(feature.icon, size: 20, color: colors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature.title(t), style: theme.textTheme.titleSmall)),
                ],
              ),
              const SizedBox(height: 4),
              Text(feature.preview(t), style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedInContent extends StatelessWidget {
  const _SignedInContent({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _EventDayLabel(),
      _QuizCheckInNotice(uid: uid),
      Card.outlined(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        semanticContainer: false,
        child: Column(
          children: [
            for (final (index, feature) in VenueEventFeature.signedInRows.indexed) ...[
              if (index > 0) const Divider(height: 1),
              _FeatureRow(feature: feature, status: _status(feature)),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      _MissionCard(uid: uid),
    ],
  );

  Widget _status(VenueEventFeature feature) => switch (feature) {
    VenueEventFeature.quiz => _QuizStatus(uid: uid),
    VenueEventFeature.stampRally => _StampRallyStatus(uid: uid),
    VenueEventFeature.profileExchange => _ExchangeStatus(uid: uid),
    VenueEventFeature.supportLt => _RegisteredStatus(registration: supportLtRegistrationProvider(uid)),
    VenueEventFeature.snsPost => _RegisteredStatus(registration: snsPostRegistrationProvider(uid)),
    // Not a row. The mission card shows progress instead.
    VenueEventFeature.mission => const SizedBox.shrink(),
  };
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature, required this.status});

  final VenueEventFeature feature;
  final Widget status;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final action = feature.action(t);
    return ListTile(
      minTileHeight: 64,
      leading: Icon(feature.icon, size: 22),
      // The status shares the title line instead of `trailing`, so with large
      // text it moves below the title rather than overflowing the tile.
      title: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(feature.title(t), style: theme.textTheme.bodyMedium),
          status,
        ],
      ),
      subtitle: action == null
          ? null
          : Text(action, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => feature.route.push<void>(context),
    );
  }
}

/// Links straight to the attendee's own round while its check-in is open. The
/// quiz list does not mark which round they registered for.
class _QuizCheckInNotice extends ConsumerWidget {
  const _QuizCheckInNotice({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(quizRegistrationProvider(uid)).value case (
      event: QuizEvent(
        :final id,
        teamSelectionStatus: QuizTeamSelectionStatus.open,
        status: QuizEventStatus.registration || QuizEventStatus.entryClosed,
      ),
      participant: QuizParticipant(checkedInAt: null),
    )) {
      final t = Translations.of(context);
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card.filled(
          margin: EdgeInsets.zero,
          color: colors.tertiaryContainer,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => QuizRoute(id).push<void>(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: colors.onTertiaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.venueEvents.quizCheckIn.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.onTertiaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.venueEvents.quizCheckIn.body,
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.onTertiaryContainer),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 20, color: colors.onTertiaryContainer),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _MissionCard extends ConsumerWidget {
  const _MissionCard({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final statuses = ref.watch(missionStatusesProvider(uid));
    final total = statuses.all.length;
    final (summary, settled) = switch (statuses.overall) {
      MissionStatus.complete => (t.mission.allComplete, true),
      MissionStatus.incomplete => (t.mission.progress(n: statuses.completeCount, total: total), true),
      MissionStatus.loading => (t.mission.loading, false),
      MissionStatus.error => (t.mission.checkFailed, false),
    };
    const mission = VenueEventFeature.mission;
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      semanticContainer: false,
      child: ListTile(
        minTileHeight: 64,
        leading: Icon(mission.icon, size: 22),
        title: Text(mission.title(t), style: theme.textTheme.bodyMedium),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (settled) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: statuses.completeCount / total,
                minHeight: 4,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => mission.route.push<void>(context),
      ),
    );
  }
}

/// Watches [provider] and logs its load failures. A row has no room for an
/// error view; the page it opens offers a retry.
AsyncValue<T> _watchLogged<T>(WidgetRef ref, ProviderListenable<AsyncValue<T>> provider) {
  ref.listen(provider, (_, next) {
    if (next case AsyncError(:final error, :final stackTrace)) {
      ref.read(talkerProvider).handle(error, stackTrace);
    }
  });
  return ref.watch(provider);
}

class _QuizStatus extends ConsumerWidget {
  const _QuizStatus({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = Translations.of(context).venueEvents.status;
    return switch (_watchLogged(ref, quizRegistrationProvider(uid)).value?.participant) {
      null => const SizedBox.shrink(),
      QuizParticipant(:final teamId?) => _StatusChip.done(status.team(team: teamId)),
      QuizParticipant(checkedInAt: _?) => _StatusChip.done(status.checkedIn),
      QuizParticipant() => _StatusChip.done(status.registered),
    };
  }
}

class _StampRallyStatus extends ConsumerWidget {
  const _StampRallyStatus({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = _watchLogged(ref, stampRallyCardProvider(uid)).value;
    final sponsorIds = _watchLogged(ref, stampRallySponsorIdsProvider).value;
    if (card == null || sponsorIds == null) {
      return const SizedBox.shrink();
    }
    final t = Translations.of(context);
    final (n, total) = (card.stampCount, sponsorIds.length);
    return _StatusChip.count(
      t.venueEvents.status.stampCount(n: n, total: total),
      semanticsLabel: t.stampRally.stampCountSemantic(n: n, total: total),
    );
  }
}

class _ExchangeStatus extends ConsumerWidget {
  const _ExchangeStatus({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = _watchLogged(ref, missionExchangeProgressProvider(uid)).value?.count ?? 0;
    if (count == 0) {
      return const SizedBox.shrink();
    }
    return _StatusChip.count(Translations.of(context).venueEvents.status.exchangeCount(n: count));
  }
}

class _RegisteredStatus<T> extends ConsumerWidget {
  const _RegisteredStatus({required this.registration});

  final ProviderListenable<AsyncValue<T>> registration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_watchLogged(ref, registration).value == null) {
      return const SizedBox.shrink();
    }
    return _StatusChip.done(Translations.of(context).venueEvents.status.registered);
  }
}

/// A finished step with a check mark, or a running count.
class _StatusChip extends StatelessWidget {
  const _StatusChip.done(this.label) : semanticsLabel = null, _done = true;

  const _StatusChip.count(this.label, {this.semanticsLabel}) : _done = false;

  final String label;
  final String? semanticsLabel;
  final bool _done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (background, foreground) = _done
        ? (colors.primaryContainer, colors.onPrimaryContainer)
        : (colors.surfaceContainerHighest, colors.onSurfaceVariant);
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(_done ? 6 : 8, 4, 8, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_done) ...[
              Icon(Icons.check_circle, size: 16, color: foreground),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                semanticsLabel: semanticsLabel,
                style: theme.textTheme.labelMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
