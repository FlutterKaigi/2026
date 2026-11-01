import 'dart:convert';

import 'package:jaspr/server.dart';
import 'package:test/test.dart';
import 'package:website/components/timetable_section.dart';
import 'package:website/constants/sponsors.dart';
import 'package:website/constants/timetable.dart';
import 'package:website/l10n/strings.dart';

void main() {
  setUpAll(Jaspr.initializeApp);

  const title = LocalizedText(ja: 'セッション', en: 'Session');
  const room = TimetableRoom(
    name: LocalizedText(ja: '会場', en: 'Room'),
    colorHex: '#6750A4',
  );
  const archive = 'https://www.youtube.com/watch?v=archive123&t=30s';

  Future<String> render(TimetableEntry entry, {AppLocale locale = AppLocale.ja}) async {
    final response = await renderComponent(
      LocaleScope(
        locale: locale,
        child: TimetableSection(
          rooms: const [room],
          programmes: {
            TimetableDay.day1: TimetableProgramme(ticks: const ['10:00', '11:00'], entries: [entry]),
            TimetableDay.day2: const TimetableProgramme(),
          },
        ),
      ),
      standalone: true,
    );
    return utf8.decode(response.body);
  }

  test('session dialog renders a localized secure YouTube archive link', () async {
    const entry = TimetableEntry.session(
      startTick: 0,
      endTick: 1,
      roomIndex: 0,
      session: TimetableSession(title: title, archiveUrl: archive),
    );
    final html = await render(entry);
    expect(html, contains('href="https://www.youtube.com/watch?v=archive123&amp;t=30s"'));
    expect(html, contains('target="_blank"'));
    expect(html, contains('rel="noopener noreferrer"'));
    expect(html, contains('アーカイブを見る'));
    expect('<a '.allMatches(html), hasLength(1));
    expect(await render(entry, locale: AppLocale.en), contains('Watch archive'));
  });

  test('venue event dialog renders its archive even without a description', () async {
    const entry = TimetableEntry.event(
      startTick: 0,
      endTick: 1,
      roomIndex: 0,
      eventLabel: title,
      eventArchiveUrl: archive,
    );
    expect(await render(entry), contains('href="https://www.youtube.com/watch?v=archive123&amp;t=30s"'));
  });

  test('full-width event provides an archive link outside a button', () async {
    const entry = TimetableEntry.event(
      startTick: 0,
      endTick: 1,
      eventLabel: title,
      eventArchiveUrl: archive,
    );
    final html = await render(entry);
    expect(html, contains('アーカイブを見る'));
    expect(html, contains('href="https://www.youtube.com/watch?v=archive123&amp;t=30s"'));
    expect(html, isNot(contains('<button')));
  });

  for (final url in <String?>[null, '', 'javascript:alert(1)', 'https://www.youtube.com.evil.example/watch?v=123']) {
    test('does not render archive links for ${url ?? 'unset'} URL', () async {
      final session = TimetableEntry.session(
        startTick: 0,
        endTick: 1,
        roomIndex: 0,
        session: TimetableSession(title: title, archiveUrl: url),
      );
      final event = TimetableEntry.event(startTick: 0, endTick: 1, eventLabel: title, eventArchiveUrl: url);
      expect(await render(session), isNot(contains('<a ')));
      expect(await render(event), isNot(contains('<a ')));
    });
  }
}
