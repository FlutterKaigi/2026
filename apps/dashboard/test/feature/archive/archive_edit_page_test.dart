import 'package:dashboard/feature/session/data/provider/session_repository.dart';
import 'package:dashboard/feature/session/ui/page/session_edit_page.dart';
import 'package:dashboard/feature/speaker/data/provider/speaker_list_state.dart';
import 'package:dashboard/feature/timeline_event/data/provider/timeline_event_repository.dart';
import 'package:dashboard/feature/timeline_event/ui/page/timeline_event_edit_page.dart';
import 'package:dashboard/feature/venue/data/provider/venue_list_state.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final now = DateTime.utc(2026, 10, 29);
  const originalUrl = 'https://youtu.be/original';
  final session = Session(
    id: 'session',
    title: const LocaleMap(ja: 'セッション', en: 'Session'),
    description: const LocaleMap(ja: '説明', en: 'Description'),
    primaryLocale: 'ja',
    startsAt: now,
    endsAt: now.add(const Duration(hours: 1)),
    venueId: 'venue',
    archiveUrl: originalUrl,
    createdAt: now,
    updatedAt: now,
  );
  final event = TimelineEvent(
    id: 'event',
    title: const LocaleMap(ja: 'イベント', en: 'Event'),
    startsAt: now,
    archiveUrl: originalUrl,
    createdAt: now,
    updatedAt: now,
  );

  for (final isSession in [true, false]) {
    group(isSession ? 'session archive editor' : 'timeline event archive editor', () {
      late _SessionRepository sessions;
      late _EventRepository events;
      Future<void> showPage(WidgetTester tester) async {
        sessions = _SessionRepository();
        events = _EventRepository();
        final router = GoRouter(
          initialLocation: '/list/edit',
          routes: [
            GoRoute(
              path: '/list',
              builder: (_, _) => const Scaffold(body: Text('list')),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (_, _) => Scaffold(
                    body: isSession ? SessionEditPage(session: session) : TimelineEventEditPage(timelineEvent: event),
                  ),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWithValue(sessions),
              timelineEventRepositoryProvider.overrideWithValue(events),
              venueListProvider.overrideWith(
                (_) => Stream.value([
                  Venue(
                    id: 'venue',
                    name: const LocaleMap(ja: '会場', en: 'Venue'),
                    createdAt: now,
                    updatedAt: now,
                  ),
                ]),
              ),
              speakerListProvider.overrideWith((_) => Stream.value([])),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
      }

      Finder archiveField() => find.widgetWithText(TextFormField, 'アーカイブ URL（YouTube）');
      String? savedUrl() => isSession ? sessions.saved.single.archiveUrl : events.saved.single.archiveUrl;

      testWidgets('prefills, trims and saves the URL', (tester) async {
        await showPage(tester);
        expect(tester.widget<TextFormField>(archiveField()).controller!.text, originalUrl);
        await tester.ensureVisible(archiveField());
        await tester.enterText(archiveField(), ' https://www.youtube.com/watch?v=updated ');
        await tester.tap(find.widgetWithText(FilledButton, '保存'));
        await tester.pumpAndSettle();
        expect(savedUrl(), 'https://www.youtube.com/watch?v=updated');
        expect(find.text('list'), findsOneWidget);
      });

      testWidgets('clears a saved URL', (tester) async {
        await showPage(tester);
        await tester.ensureVisible(archiveField());
        await tester.enterText(archiveField(), '   ');
        await tester.tap(find.widgetWithText(FilledButton, '保存'));
        await tester.pumpAndSettle();
        expect(savedUrl(), isNull);
      });

      testWidgets('blocks non-YouTube URLs', (tester) async {
        await showPage(tester);
        await tester.ensureVisible(archiveField());
        await tester.enterText(archiveField(), 'https://youtube.com.example.com/watch?v=x');
        await tester.tap(find.widgetWithText(FilledButton, '保存'));
        await tester.pumpAndSettle();
        expect(sessions.saved, isEmpty);
        expect(events.saved, isEmpty);
        expect(find.text('YouTube の HTTPS URL を入力してください'), findsOneWidget);
      });
    });
  }
}

class _SessionRepository implements SessionRepository {
  List<Session> saved = const [];
  @override
  Future<void> save(Session value) async {
    saved = [...saved, value];
  }

  @override
  Future<void> delete(String id) async {}
  @override
  Stream<List<Session>> watchAll() => const Stream.empty();
}

class _EventRepository implements TimelineEventRepository {
  List<TimelineEvent> saved = const [];
  @override
  Future<void> save(TimelineEvent value) async {
    saved = [...saved, value];
  }

  @override
  Future<void> delete(String id) async {}
  @override
  Stream<List<TimelineEvent>> watchAll() => const Stream.empty();
}
