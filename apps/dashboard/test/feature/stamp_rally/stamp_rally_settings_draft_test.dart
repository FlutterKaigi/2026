import 'dart:async';

import 'package:dashboard/core/env.dart';
import 'package:dashboard/core/event_environment/event_environment.dart';
import 'package:dashboard/feature/sponsor/data/provider/sponsor_list_state.dart';
import 'package:dashboard/feature/stamp_rally/data/provider/stamp_rally_state.dart';
import 'package:dashboard/feature/stamp_rally/ui/page/stamp_rally_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  late _Repository repository;
  setUp(() => repository = _Repository());
  tearDown(() => repository.changes.close());
  final field = find.byKey(const Key('stamp-rally-checkpoints'));
  final toggle = find.byKey(const Key('stamp-rally-is-open'));

  Future<void> show(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stampRallyRepositoryProvider.overrideWithValue(repository),
          dashboardFlavorProvider.overrideWithValue(Flavor.prod),
          sponsorListProvider.overrideWith((_) => Stream.value(const <Sponsor>[])),
        ],
        child: const MaterialApp(home: Scaffold(body: StampRallyPage())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('editing checkpoints, opening reception, then saving preserves the edited checkpoint', (tester) async {
    await show(tester);
    expect(tester.widget<TextField>(field).controller!.text, '7, 14, 22');
    await tester.enterText(field, '1');
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    final draftAfterToggle = tester.widget<TextField>(field).controller!.text;
    expect(repository.current.isOpen, isTrue);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(
      repository.current.checkpoints,
      [1],
      reason:
          'Draft after the switch was "$draftAfterToggle"; saved requests were '
          '${repository.saved.map((value) => '${value.checkpoints}/${value.isOpen}').toList()}',
    );
  });

  testWidgets('a saved checkpoint update refreshes a clean field but preserves a draft', (tester) async {
    await show(tester);
    repository.changes.add(const StampRallySettings(checkpoints: [3, 6], isOpen: false));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, '3, 6');
    await tester.enterText(field, '1, 2');
    repository.changes.add(const StampRallySettings(checkpoints: [4, 8], isOpen: true));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, '1, 2');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repository.current.checkpoints, [1, 2]);
    expect(repository.current.isOpen, isTrue);
  });

  testWidgets('a failed reception update preserves the unsaved checkpoint', (tester) async {
    await show(tester);
    await tester.enterText(field, '1');
    repository.failSave = true;
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(repository.current.isOpen, isFalse);
    expect(tester.widget<TextField>(field).controller!.text, '1');
    expect(find.textContaining('保存に失敗しました'), findsOneWidget);
    repository.failSave = false;
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repository.current.checkpoints, [1]);
  });

  for (final draft in ['01', '1 ', '07, 14, 22 ']) {
    testWidgets('normalizes saved "$draft" and follows later saved checkpoints', (tester) async {
      await show(tester);
      await tester.enterText(field, draft);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, repository.current.checkpoints.join(', '));
      repository.changes.add(const StampRallySettings(checkpoints: [3, 6], isOpen: false));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, '3, 6');
    });
  }

  testWidgets('does not normalize over a newer draft typed while saving', (tester) async {
    await show(tester);
    await tester.enterText(field, '01');
    repository.saveGate = Completer<void>();
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.enterText(field, '2');
    repository.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(repository.current.checkpoints, [1]);
    expect(tester.widget<TextField>(field).controller!.text, '2');
  });

  testWidgets('saving checkpoints before opening reception retains the new checkpoint', (tester) async {
    await show(tester);
    await tester.enterText(field, '1');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repository.current.checkpoints, [1]);
    expect(repository.current.isOpen, isFalse);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(repository.current.checkpoints, [1]);
    expect(repository.current.isOpen, isTrue);
    expect(tester.widget<TextField>(field).controller!.text, '1');
  });
}

class _Repository implements StampRallyRepository {
  StampRallySettings current = StampRallySettings.defaults;
  final changes = StreamController<StampRallySettings>.broadcast();
  final saved = <StampRallySettings>[];
  bool failSave = false;
  Completer<void>? saveGate;
  @override
  Stream<StampRallySettings> watchSettings() async* {
    yield current;
    yield* changes.stream;
  }

  @override
  Stream<Set<String>> watchSponsorIds() => Stream.value({});
  @override
  Future<void> saveSettings(StampRallySettings value) async {
    await saveGate?.future;
    if (failSave) throw Exception("offline");
    saved.add(value);
    current = value;
    // Firestore watchSettings emits changed settings after each successful write.
    changes.add(value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
