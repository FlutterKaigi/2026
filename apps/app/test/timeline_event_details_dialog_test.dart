import 'dart:ui' show SemanticsHitTestBehavior;

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/timeline_event_details_dialog.dart';
import 'package:app/feature/session/ui/widget/youtube_archive_player.dart';
import 'package:data/data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_youtube_archive_surface.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  testWidgets('opens a YouTube archive without a venue or description', (tester) async {
    final launched = <Uri>[];
    const archiveUrl = 'https://youtu.be/dQw4w9WgXcQ?t=30';
    await _openDialog(tester, description: null, archiveUrl: archiveUrl, launched: launched);

    expect(find.byType(YouTubeArchivePlayer), findsOneWidget);
    expect(launched, isEmpty);
    expect(
      tester.getTopLeft(find.byType(YouTubeArchivePlayer)).dy,
      lessThan(tester.getTopLeft(find.text('2026/10/30')).dy),
    );
    await tester.tap(find.text('YouTubeで開く'));
    await tester.pumpAndSettle();

    expect(launched, [Uri.parse(archiveUrl)]);
    expect(find.byKey(const ValueKey('timeline-event-details-dialog')), findsOneWidget);
  });

  testWidgets(
    'Web archive dialog lets pointer events reach the embedded player',
    (tester) async {
      await _openDialog(
        tester,
        description: null,
        archiveUrl: 'https://youtu.be/dQw4w9WgXcQ',
        launched: [],
      );

      for (
        SemanticsNode? node = tester.getSemantics(find.byType(YouTubeArchivePlayer));
        node != null;
        node = node.parent
      ) {
        expect(
          node.getSemanticsData().hitTestBehavior,
          isNot(SemanticsHitTestBehavior.opaque),
          reason: 'An opaque dialog ancestor intercepts clicks on the Web iframe.',
        );
      }
      final barrier = tester.getSemantics(find.bySemanticsLabel('Dismiss').last);
      expect(barrier.getSemanticsData().hitTestBehavior, SemanticsHitTestBehavior.transparent);
      expect(barrier.getSemanticsData().hasAction(SemanticsAction.dismiss), isTrue);
      expect(
        tester.getSemantics(find.widgetWithText(TextButton, 'Close')).getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(YouTubeArchivePlayer), findsNothing);
    },
    skip: !kIsWeb,
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('archive dialog keeps barrier dismissal', (tester) async {
    await _openDialog(
      tester,
      description: null,
      archiveUrl: 'https://youtu.be/dQw4w9WgXcQ',
      launched: [],
    );

    await tester.tapAt(tester.getTopLeft(find.byType(YouTubeArchivePlayer)) + const Offset(-8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(YouTubeArchivePlayer), findsOneWidget);

    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.byType(YouTubeArchivePlayer), findsNothing);
  });

  testWidgets('archive dialog retains the focus trap and Escape dismissal', (tester) async {
    await _openDialog(
      tester,
      description: null,
      archiveUrl: 'https://youtu.be/dQw4w9WgXcQ',
      launched: [],
    );
    final context = tester.element(find.byType(YouTubeArchivePlayer));
    final route = ModalRoute.of(context)!;
    expect(route.traversalEdgeBehavior, TraversalEdgeBehavior.closedLoop);
    expect(route.barrierLabel, MaterialLocalizations.of(context).modalBarrierDismissLabel);

    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      var insideDialog = false;
      FocusManager.instance.primaryFocus!.context!.visitAncestorElements((element) {
        insideDialog = insideDialog || element.widget is AlertDialog;
        return true;
      });
      expect(insideDialog, isTrue, reason: 'Tab must stay in the modal dialog.');
    }
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus!.context!.findAncestorWidgetOfExactType<AlertDialog>(), isNotNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(YouTubeArchivePlayer), findsNothing);
  });

  testWidgets('hides missing or invalid event archive URLs', (tester) async {
    for (final url in [null, '', 'https://example.com/archive', 'javascript:alert(1)']) {
      await _openDialog(tester, description: null, archiveUrl: url, launched: []);
      expect(find.byType(YouTubeArchivePlayer), findsNothing, reason: '$url');
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('opens a URL in the description only when the URL is tapped', (tester) async {
    const formUrl = 'https://docs.google.com/forms/d/e/1FAIpQLSe/viewform?usp=publish-editor';
    final launched = <Uri>[];
    await _openDialog(
      tester,
      description: '事前に質問を募集中。$formUrl\n\n当日の質問もお待ちしています。',
      launched: launched,
    );

    await tester.tapOnText(find.textRange.ofSubstring('当日の質問'));
    await tester.pump();
    expect(launched, isEmpty);

    await tester.tapOnText(find.textRange.ofSubstring(formUrl));
    await tester.pump();
    expect(launched, [Uri.parse(formUrl)]);
  });

  testWidgets('ends a URL before trailing punctuation and Japanese text', (tester) async {
    final launched = <Uri>[];
    await _openDialog(
      tester,
      description: '詳細は https://example.com/a. 申込は https://example.com/b。会場 (https://example.com/c)',
      launched: launched,
    );

    for (final url in ['https://example.com/a', 'https://example.com/b', 'https://example.com/c']) {
      await tester.tapOnText(find.textRange.ofSubstring(url));
      await tester.pump();
    }

    expect(launched, [
      Uri.parse('https://example.com/a'),
      Uri.parse('https://example.com/b'),
      Uri.parse('https://example.com/c'),
    ]);
  });
}

Future<void> _openDialog(
  WidgetTester tester, {
  required String? description,
  required List<Uri> launched,
  String? archiveUrl,
}) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [youtubeArchiveSurfaceBuilderProvider.overrideWithValue(fakeYouTubeArchiveSurface)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showTimelineEventDetailsDialog(
                  context,
                  entry: SessionTimetableEntry.timelineEvent(
                    timelineEvent: _entry.timelineEvent!.copyWith(archiveUrl: archiveUrl),
                    venue: null,
                  ),
                  description: description,
                  launcher: (uri) async {
                    launched.add(uri);
                    return true;
                  },
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

final _entry = SessionTimetableEntry.timelineEvent(
  timelineEvent: TimelineEvent(
    id: 'panel-discussion',
    title: const LocaleMap(ja: 'パネルディスカッション', en: 'Panel discussion'),
    startsAt: DateTime.utc(2026, 10, 30, 7, 50),
    endsAt: DateTime.utc(2026, 10, 30, 8, 30),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  venue: null,
);
