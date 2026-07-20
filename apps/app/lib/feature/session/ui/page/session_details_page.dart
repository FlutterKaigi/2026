import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/session/data/provider/session_detail_provider.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/session_details_content_widget.dart';
import 'package:app/feature/session/ui/widget/session_details_message_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Shows details for one Firestore-backed session.
class SessionDetailsPage extends ConsumerWidget {
  const SessionDetailsPage({
    required this.sessionId,
    super.key,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final detail = ref.watch(sessionDetailProvider(sessionId));

    return switch (detail) {
      AsyncData(:final value) =>
        value == null
            ? Scaffold(
                appBar: AppBar(title: Text(t.sessionDetails.title)),
                body: SessionDetailsMessageStateWidget(
                  icon: Icons.search_off_outlined,
                  message: t.sessionDetails.notFound,
                ),
              )
            : SessionDetailsContentWidget(data: value),
      AsyncError() => Scaffold(
        appBar: AppBar(title: Text(t.sessionDetails.title)),
        body: SessionDetailsMessageStateWidget(
          icon: Icons.error_outline,
          message: t.sessionDetails.error,
          action: FilledButton.icon(
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh),
            label: Text(t.common.retry),
          ),
        ),
      ),
      AsyncLoading() => Scaffold(
        appBar: AppBar(title: Text(t.sessionDetails.title)),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
    };
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(sessionListProvider);
    ref.invalidate(sessionVenueListProvider);
    ref.invalidate(sessionSpeakerListProvider);
  }
}
