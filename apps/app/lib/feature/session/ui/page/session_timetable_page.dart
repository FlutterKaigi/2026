import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/session_timetable_empty_state_widget.dart';
import 'package:app/feature/session/ui/widget/session_timetable_error_state_widget.dart';
import 'package:app/feature/session/ui/widget/session_timetable_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Shows the conference session timetable.
class SessionTimetablePage extends HookConsumerWidget {
  const SessionTimetablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final timetable = ref.watch(sessionTimetableProvider);
    final scrollController = useScrollController();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.sessionTimetable.title),
        actions: [
          IconButton(
            tooltip: t.sessionBookmark.openBookmarked,
            onPressed: () => const BookmarkedSessionsRoute().push<void>(context),
            icon: const Icon(Icons.bookmarks_outlined),
          ),
        ],
      ),
      body: switch (timetable) {
        AsyncData(:final value) when value.isEmpty => SessionTimetableEmptyStateWidget(
          data: value,
          scrollController: scrollController,
        ),
        AsyncData(:final value) => SessionTimetableListWidget(
          data: value,
          scrollController: scrollController,
        ),
        AsyncError() => SessionTimetableErrorStateWidget(
          onRetry: () => _retry(ref),
        ),
        AsyncLoading() => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      },
    );
  }

  void _retry(WidgetRef ref) {
    ref.invalidate(sessionListProvider);
    ref.invalidate(sessionTimelineEventListProvider);
    ref.invalidate(sessionVenueListProvider);
    ref.invalidate(sessionSpeakerListProvider);
  }
}
