import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/live_captions/data/provider/live_captions_repository.dart';
import 'package:app/feature/live_captions/ui/page/live_caption_room_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Widget buildPage(LiveCaptionsRepository repository) {
    return TranslationProvider(
      child: ProviderScope(
        overrides: [
          liveCaptionsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const LiveCaptionRoomPage(venueId: 'hall-a'),
        ),
      ),
    );
  }

  const segment = LiveCaptionSegment(
    id: '1789000000000-000001',
    seq: 1,
    srcLang: 'ja',
    srcText: 'ようこそ FlutterKaigi へ。',
    ja: 'ようこそ FlutterKaigi へ。',
    en: 'Welcome to FlutterKaigi.',
  );

  testWidgets('配信中は字幕セグメントと interim が表示される', (tester) async {
    const repository = _FakeLiveCaptionsRepository(
      room: LiveCaptionRoom(
        id: 'hall-a',
        isLive: true,
        sourceLang: 'ja-JP',
        interim: LiveCaptionInterim(text: '次のトピックは…', srcLang: 'ja'),
      ),
      segments: [segment],
    );

    await tester.pumpWidget(buildPage(repository));
    await tester.pumpAndSettle();

    expect(find.text('ようこそ FlutterKaigi へ。'), findsOneWidget);
    expect(find.text('次のトピックは…'), findsOneWidget);
  });

  testWidgets('言語切替で英語テキストに切り替わる', (tester) async {
    const repository = _FakeLiveCaptionsRepository(
      room: LiveCaptionRoom(id: 'hall-a', isLive: true),
      segments: [segment],
    );

    await tester.pumpWidget(buildPage(repository));
    await tester.pumpAndSettle();

    expect(find.text('ようこそ FlutterKaigi へ。'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to FlutterKaigi.'), findsOneWidget);
    expect(find.text('ようこそ FlutterKaigi へ。'), findsNothing);
  });

  testWidgets('enabled=false では字幕を表示しない', (tester) async {
    const repository = _FakeLiveCaptionsRepository(
      room: LiveCaptionRoom(id: 'hall-a', enabled: false, isLive: true),
      segments: [segment],
    );

    await tester.pumpWidget(buildPage(repository));
    await tester.pumpAndSettle();

    expect(find.text('ようこそ FlutterKaigi へ。'), findsNothing);
    expect(
      find.text(TranslationsJa().liveCaptions.room.disabled),
      findsOneWidget,
    );
  });

  testWidgets('ルーム未作成なら待機メッセージを表示する', (tester) async {
    const repository = _FakeLiveCaptionsRepository(room: null, segments: []);

    await tester.pumpWidget(buildPage(repository));
    await tester.pumpAndSettle();

    expect(
      find.text(TranslationsJa().liveCaptions.room.waiting),
      findsOneWidget,
    );
  });
}

final class _FakeLiveCaptionsRepository implements LiveCaptionsRepository {
  const _FakeLiveCaptionsRepository({
    required this.room,
    required this.segments,
  });

  final LiveCaptionRoom? room;
  final List<LiveCaptionSegment> segments;

  @override
  Stream<LiveCaptionRoom?> watchRoom(String roomId) => Stream.value(room);

  @override
  Stream<List<LiveCaptionRoom>> watchRooms() =>
      Stream.value([if (room case final room?) room]);

  @override
  Stream<List<LiveCaptionSegment>> watchLatestSegments(
    String roomId, {
    int limit = 50,
  }) => Stream.value(segments);
}
