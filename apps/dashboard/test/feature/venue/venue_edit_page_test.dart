import 'dart:async';

import 'package:dashboard/feature/venue/data/provider/venue_repository.dart';
import 'package:dashboard/feature/venue/ui/page/venue_edit_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  late _FakeVenueRepository repository;
  late GoRouter router;

  Future<void> showEditPage(WidgetTester tester) async {
    repository = _FakeVenueRepository();
    router = GoRouter(
      initialLocation: '/venues/new',
      routes: [
        GoRoute(
          path: '/venues',
          pageBuilder: (_, _) => const NoTransitionPage(child: Scaffold(body: Text('venue list'))),
          routes: [
            GoRoute(
              path: 'new',
              pageBuilder: (_, _) => const NoTransitionPage(child: Scaffold(body: VenueEditPage())),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [venueRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'ホールA');
    await tester.enterText(find.byType(TextFormField).at(1), 'Hall A');
  }

  testWidgets('saves a venue and returns to the list', (tester) async {
    await showEditPage(tester);

    await tester.tap(find.widgetWithText(FilledButton, '作成'));
    await tester.pumpAndSettle();

    expect(repository.saved.single.name, const LocaleMap(ja: 'ホールA', en: 'Hall A'));
    expect(find.text('venue list'), findsOneWidget);
  });

  for (final outcome in ['succeeds', 'fails']) {
    testWidgets('finishes quietly when a save $outcome after leaving the page', (
      tester,
    ) async {
      await showEditPage(tester);
      repository.pendingSave = Completer<void>();

      await tester.tap(find.widgetWithText(FilledButton, '作成'));
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(VenueEditPage), findsNothing);

      if (outcome == 'fails') {
        repository.pendingSave!.completeError(StateError('offline'));
      } else {
        repository.pendingSave!.complete();
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('venue list'), findsOneWidget);
    });
  }
}

class _FakeVenueRepository implements VenueRepository {
  final saved = <Venue>[];
  Completer<void>? pendingSave;

  @override
  Future<void> save(Venue venue) async {
    await pendingSave?.future;
    saved.add(venue);
  }

  @override
  Stream<List<Venue>> watchAll() => const Stream.empty();

  @override
  Future<void> delete(String id) async {}
}
