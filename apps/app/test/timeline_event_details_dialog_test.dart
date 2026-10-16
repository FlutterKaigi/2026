import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/timeline_event_details_dialog.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

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
  required String description,
  required List<Uri> launched,
}) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTimelineEventDetailsDialog(
                context,
                entry: _entry,
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
