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
    final errorMessage = t.sessionBookmark.updateFailed;

    return IconButton(
      tooltip: label,
      isSelected: isBookmarked,
      selectedIcon: const Icon(Icons.bookmark),
      icon: const Icon(Icons.bookmark_outline),
      onPressed: canToggle
          ? () => unawaited(
              _toggleBookmark(
                context: context,
                ref: ref,
                sessionId: sessionId,
                errorMessage: errorMessage,
              ),
            )
          : null,
    );
  }
}

Future<void> _toggleBookmark({
  required BuildContext context,
  required WidgetRef ref,
  required String sessionId,
  required String errorMessage,
}) async {
  try {
    await ref.read(bookmarkedSessionIdsProvider.notifier).toggle(sessionId);
  } on Exception {
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
  }
}
