import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/session/data/provider/bookmarked_sessions_provider.dart';
import 'package:app/feature/session/data/provider/session_time_format.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/session_card_widget.dart';
import 'package:app/feature/session/ui/widget/session_details_message_state_widget.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BookmarkedSessionsPage extends ConsumerWidget {
  const BookmarkedSessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final bookmarkedSessions = ref.watch(bookmarkedSessionsProvider);
    final timeFormat = ref.watch(sessionTimeFormatProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(t.bookmarkedSessions.title),
          ),
          switch (bookmarkedSessions) {
            AsyncData(:final value) when value.isEmpty => SliverFillRemaining(
              hasScrollBody: false,
              child: _BookmarkedSessionsEmptyStateWidget(
                onOpenSessions: () => const SessionTimetableRoute().go(context),
              ),
            ),
            AsyncData(:final value) => _BookmarkedSessionsListWidget(
              data: value,
              timeFormat: timeFormat,
            ),
            AsyncError() => SliverFillRemaining(
              hasScrollBody: false,
              child: SessionDetailsMessageStateWidget(
                icon: Icons.error_outline,
                message: t.bookmarkedSessions.error,
                action: FilledButton.icon(
                  onPressed: () => _refresh(ref),
                  icon: const Icon(Icons.refresh),
                  label: Text(t.common.retry),
                ),
              ),
            ),
            AsyncLoading() => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
          },
        ],
      ),
    );
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(sessionListProvider);
    ref.invalidate(sessionVenueListProvider);
    ref.invalidate(sessionSpeakerListProvider);
    ref.invalidate(bookmarkedSessionIdsProvider);
  }
}

class _BookmarkedSessionsListWidget extends StatelessWidget {
  const _BookmarkedSessionsListWidget({
    required this.data,
    required this.timeFormat,
  });

  final BookmarkedSessionsData data;
  final EventTimeFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList.builder(
        itemCount: data.entries.length * 2 - 1,
        itemBuilder: (context, index) {
          if (index.isOdd) {
            return const SizedBox(height: 16);
          }

          final entry = data.entries[index ~/ 2];
          return SessionCardWidget(
            entry: entry,
            timeFormat: timeFormat,
            onTap: () => SessionDetailsRoute(sessionId: entry.id).push<void>(context),
          );
        },
      ),
    );
  }
}

class _BookmarkedSessionsEmptyStateWidget extends StatelessWidget {
  const _BookmarkedSessionsEmptyStateWidget({
    required this.onOpenSessions,
  });

  final VoidCallback onOpenSessions;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              t.bookmarkedSessions.emptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.bookmarkedSessions.emptyBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onOpenSessions,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(t.bookmarkedSessions.openSessions),
            ),
          ],
        ),
      ),
    );
  }
}
