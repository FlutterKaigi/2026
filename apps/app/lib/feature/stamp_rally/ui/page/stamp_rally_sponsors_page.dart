import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_page_content.dart';
import 'package:app/feature/auth/ui/widget/authenticated_body.dart';
import 'package:app/feature/auth/ui/widget/centered_sign_in_card.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:app/feature/stamp_rally/data/stamp_rally_provider.dart';
import 'package:app/feature/stamp_rally/ui/page/stamp_rally_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The signed-in attendee's stamp collection, identified by sponsor.
class StampRallySponsorsPage extends StatelessWidget {
  const StampRallySponsorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.stampRally.sponsorsTitle)),
      body: AuthenticatedBody(
        signedOut: CenteredSignInCard(
          title: t.auth.signIn.required,
          description: t.stampRally.sponsorsSignInRequired,
          returnTo: const StampRallySponsorsRoute().location,
        ),
        builder: (uid) => _SponsorCollection(uid: uid),
      ),
    );
  }
}

class _SponsorCollection extends ConsumerWidget {
  const _SponsorCollection({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final card = ref.watch(stampRallyCardProvider(uid));
    final sponsorIds = ref.watch(stampRallySponsorIdsProvider);
    final sponsors = ref.watch(sponsorListProvider);
    final values = [card, sponsorIds, sponsors];

    void retry() {
      ref
        ..invalidate(stampRallyCardProvider(uid))
        ..invalidate(stampRallySponsorIdsProvider)
        ..invalidate(sponsorListProvider);
    }

    if (values.firstWhere((value) => value.hasError, orElse: () => const AsyncLoading()) case AsyncError(
      :final error,
    )) {
      return AppErrorView(error: error, onRetry: retry);
    }
    if (values.any((value) => !value.hasValue)) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final stamps = card.requireValue.stamps;
    final sponsorsById = {for (final sponsor in sponsors.requireValue) sponsor.id: sponsor};
    // Retain collected stamps when a sponsor is no longer participating.
    final ids = {...sponsorIds.requireValue, ...stamps.keys}.toList()..sort();

    return AppPageContent(
      maxWidth: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.stampRally.sponsorsDescription),
          const SizedBox(height: 16),
          Text(
            t.stampRally.stampCountSemantic(n: stamps.length, total: ids.length),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (ids.isEmpty)
            Text(t.stampRally.sponsorsEmpty)
          else
            for (final id in ids) ...[
              _SponsorStampTile(id: id, sponsor: sponsorsById[id], acquiredAt: stamps[id]),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _SponsorStampTile extends StatelessWidget {
  const _SponsorStampTile({required this.id, required this.sponsor, required this.acquiredAt});

  final String id;
  final Sponsor? sponsor;
  final DateTime? acquiredAt;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final name = sponsor?.name.resolve(Localizations.localeOf(context)).trim();
    final time = acquiredAt;
    final statusColor = time == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary;

    return Card.outlined(
      key: ValueKey('stamp-sponsor-$id'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name == null || name.isEmpty ? t.stampRally.sponsorUnavailable(id: id) : name,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              time == null ? t.stampRally.notAcquired : t.stampRally.acquired,
              style: theme.textTheme.labelLarge?.copyWith(color: statusColor),
            ),
            if (time != null) ...[
              const SizedBox(height: 4),
              Text(
                t.stampRally.sponsorAcquiredAt(date: formatStampRallyTime(context, time)),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
