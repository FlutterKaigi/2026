import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/session/data/provider/bookmarked_sessions_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SessionBookmarkButton extends ConsumerWidget {
  const SessionBookmarkButton({
    required this.sessionId,
    super.key,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final bookmarkedSessionIds = ref.watch(bookmarkedSessionIdsProvider);
    final isBookmarked = switch (bookmarkedSessionIds) {
      AsyncData(:final value) => value.contains(sessionId),
      _ => false,
    };
    final canToggle = bookmarkedSessionIds is AsyncData<Set<String>>;
    final label = isBookmarked ? t.sessionBookmark.remove : t.sessionBookmark.add;

    return IconButton(
      tooltip: label,
      isSelected: isBookmarked,
      selectedIcon: const Icon(Icons.bookmark),
      icon: const Icon(Icons.bookmark_outline),
      onPressed: canToggle
          ? () {
              unawaited(ref.read(bookmarkedSessionIdsProvider.notifier).toggle(sessionId));
            }
          : null,
    );
  }
}
