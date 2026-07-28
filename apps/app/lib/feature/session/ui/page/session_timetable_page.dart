import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/settings_icon_button.dart';
import 'package:app/core/util/window_size.dart';
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
    final viewMode = useState(SessionTimetableViewMode.list);
    final windowSize = WindowSize.fromWidth(MediaQuery.sizeOf(context).width);
    final timetableData = switch (timetable) {
      AsyncData(:final value) => value,
      _ => null,
    };

    Future<void> openBookmarked() => const BookmarkedSessionsRoute().push<void>(context);
    Future<void> openSearch() => const SessionSearchRoute().push<void>(context);

    void toggleViewMode() {
      viewMode.value = switch (viewMode.value) {
        SessionTimetableViewMode.list => SessionTimetableViewMode.rooms,
        SessionTimetableViewMode.rooms => SessionTimetableViewMode.list,
      };
    }

    final viewModeTooltip = switch (viewMode.value) {
      SessionTimetableViewMode.list => t.sessionTimetable.view.openRooms,
      SessionTimetableViewMode.rooms => t.sessionTimetable.view.openList,
    };
    final viewModeIcon = switch (viewMode.value) {
      SessionTimetableViewMode.list => Icons.grid_view_outlined,
      SessionTimetableViewMode.rooms => Icons.view_agenda_outlined,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(t.sessionTimetable.title),
        actions: [
          if (windowSize == WindowSize.compact) ...[
            if (timetableData?.hasAnyEntries ?? false)
              IconButton(
                tooltip: t.sessionSearch.title,
                onPressed: openSearch,
                icon: const Icon(Icons.search),
              ),
            if (timetableData?.hasAnyEntries ?? false)
              IconButton(
                tooltip: viewModeTooltip,
                onPressed: toggleViewMode,
                icon: Icon(viewModeIcon),
              ),
            IconButton(
              tooltip: t.sessionBookmark.openBookmarked,
              onPressed: openBookmarked,
              icon: const Icon(Icons.bookmarks_outlined),
            ),
          ] else ...[
            if (timetableData?.hasAnyEntries ?? false)
              IconButton(
                tooltip: t.sessionSearch.title,
                onPressed: openSearch,
                icon: const Icon(Icons.search),
              ),
            if (timetableData?.hasAnyEntries ?? false)
              IconButton(
                tooltip: viewModeTooltip,
                onPressed: toggleViewMode,
                icon: Icon(viewModeIcon),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Tooltip(
                message: t.sessionBookmark.openBookmarked,
                child: FilledButton.tonalIcon(
                  onPressed: openBookmarked,
                  icon: const Icon(Icons.bookmarks_outlined),
                  label: Text(t.sessionBookmark.openBookmarked),
                ),
              ),
            ),
          ],
          const SettingsIconButton(),
        ],
      ),
      body: switch (timetable) {
        AsyncData(:final value) when !value.hasAnyEntries => SessionTimetableEmptyStateWidget(
          scrollController: scrollController,
        ),
        AsyncData(:final value) => SessionTimetableListWidget(
          data: value,
          viewMode: viewMode.value,
        ),
        AsyncError(:final error) => SessionTimetableErrorStateWidget(
          error: error,
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
