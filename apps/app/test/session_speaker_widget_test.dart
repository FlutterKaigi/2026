import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/session/ui/widget/session_speaker_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  test('builds an X profile URL from a normalized xId', () {
    expect(
      speakerXProfileUri(' @flutterkaigi '),
      Uri.parse('https://x.com/flutterkaigi'),
    );
    expect(speakerXProfileUri(null), isNull);
    expect(speakerXProfileUri('  @  '), isNull);
  });

  testWidgets('shows every long speaker name at narrow width without overflow', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 480);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final speaker in _speakers) SessionSpeakerChipWidget(speaker: speaker),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    for (final speaker in _speakers) {
      final nameFinder = find.byKey(
        ValueKey('session-speaker-name-${speaker.id}'),
      );
      final avatarFinder = find.byKey(
        ValueKey('session-speaker-avatar-${speaker.id}'),
      );
      expect(nameFinder, findsOneWidget);
      expect(avatarFinder, findsOneWidget);
      expect(tester.widget<Text>(nameFinder).maxLines, isNull);
      expect(tester.getSize(avatarFinder), const Size.square(24));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens X only from an avatar with xId', (tester) async {
    Uri? launchedUri;
    var parentTapCount = 0;

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => parentTapCount += 1,
              child: SessionSpeakerChipWidget(
                speaker: _speakers.first,
                launcher: (uri) async {
                  launchedUri = uri;
                  return true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('session-speaker-x-link-speaker-a')),
    );
    await tester.pump();

    expect(launchedUri, Uri.parse('https://x.com/speaker_a'));
    expect(parentTapCount, 0);
  });

  testWidgets('does not make the avatar interactive without xId', (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: SessionSpeakerChipWidget(speaker: _speakers.last),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('session-speaker-x-link-speaker-b')),
      findsNothing,
    );
  });
}

final _speakers = [
  Speaker(
    id: 'speaker-a',
    name: 'とても長い名前でも省略せずに表示する登壇者 A',
    xId: 'speaker_a',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Speaker(
    id: 'speaker-b',
    name: 'Another speaker whose full name must remain visible',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];
