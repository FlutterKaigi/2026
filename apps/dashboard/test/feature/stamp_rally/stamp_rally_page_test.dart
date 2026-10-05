import 'package:dashboard/core/env.dart';
import 'package:dashboard/core/event_environment/event_environment.dart';
import 'package:dashboard/feature/sponsor/data/provider/sponsor_list_state.dart';
import 'package:dashboard/feature/stamp_rally/data/provider/stamp_rally_state.dart';
import 'package:dashboard/feature/stamp_rally/ui/page/stamp_rally_page.dart';
import 'package:dashboard/feature/stamp_rally/ui/print/stamp_rally_print.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  late _FakeStampRallyRepository repository;

  setUp(() => repository = _FakeStampRallyRepository());

  Future<void> showPage(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stampRallyRepositoryProvider.overrideWithValue(repository),
          dashboardFlavorProvider.overrideWithValue(Flavor.prod),
          sponsorListProvider.overrideWith((_) => Stream.value([_sponsor('sponsor-a', 'スポンサーA')])),
        ],
        child: const MaterialApp(home: Scaffold(body: StampRallyPage())),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('checkpoints must be 1 to 5 strictly ascending positive integers', () {
    expect(parseCheckpoints('7, 14, 22'), [7, 14, 22]);
    for (final invalid in ['', '0', '7, 7', '14, 7', '1,2,3,4,5,6', 'a', '1,,2']) {
      expect(parseCheckpoints(invalid), isNull, reason: invalid);
    }
  });

  testWidgets('saves valid checkpoints and rejects invalid ones', (tester) async {
    await showPage(tester);
    final field = find.byKey(const Key('stamp-rally-checkpoints'));
    expect(tester.widget<TextField>(field).controller!.text, '7, 14, 22');

    await tester.enterText(field, '14, 7');
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('1〜5個の正の整数を昇順にカンマ区切りで入力してください'), findsOneWidget);
    expect(repository.saved, isEmpty);

    await tester.enterText(field, '5, 10');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repository.saved.single.checkpoints, [5, 10]);
    expect(repository.saved.single.isOpen, isFalse);
  });

  testWidgets('toggles sponsors and lists targets whose sponsor was deleted', (tester) async {
    repository.sponsorIds = {'deleted-sponsor'};
    await showPage(tester);

    expect(find.text('（削除済みのスポンサー）'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('stamp-rally-sponsor-sponsor-a')));
    await tester.tap(find.byKey(const ValueKey('stamp-rally-sponsor-deleted-sponsor')));
    await tester.pump();

    expect(repository.toggles, [('sponsor-a', true), ('deleted-sponsor', false)]);
  });

  testWidgets('shows QR code URLs on the flavor origin', (tester) async {
    await showPage(tester);
    await tester.tap(find.text('QRコードを表示'));
    await tester.pumpAndSettle();

    expect(find.text('スポンサーA（sponsor-a）'), findsOneWidget);
    expect(find.text('https://2026-app.flutterkaigi.jp/s/${'a' * 64}'), findsOneWidget);
    expect(find.text('https://2026-app.flutterkaigi.jp/s/${'b' * 64}'), findsOneWidget);
    expect(find.text('https://2026-app.flutterkaigi.jp/s/${'c' * 64}'), findsOneWidget);
  });

  test('print document escapes labels and embeds an SVG per code', () {
    final html = stampRallyPrintHtml([(label: '<A&B>', url: 'https://example.test/s/x')]);
    expect(html, contains('&lt;A&amp;B&gt;'));
    expect('<svg'.allMatches(html), hasLength(1));
  });
}

Sponsor _sponsor(String id, String name) => Sponsor(
  id: id,
  name: LocaleMap(ja: name, en: name),
  description: const LocaleMap(ja: '', en: ''),
  tier: SponsorTier.gold,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _FakeStampRallyRepository implements StampRallyRepository {
  Set<String> sponsorIds = {};
  final saved = <StampRallySettings>[];
  final toggles = <(String, bool)>[];

  @override
  Stream<StampRallySettings> watchSettings() => Stream.value(StampRallySettings.defaults);

  @override
  Stream<Set<String>> watchSponsorIds() => Stream.value(sponsorIds);

  @override
  Future<void> saveSettings(StampRallySettings settings) async => saved.add(settings);

  @override
  Future<void> setSponsorEnabled(String sponsorId, {required bool enabled}) async => toggles.add((sponsorId, enabled));

  @override
  Future<StampRallyQrCodes> fetchQrCodes() async => StampRallyQrCodes(
    sponsors: [(sponsorId: 'sponsor-a', token: 'a' * 64)],
    reward: 'b' * 64,
    thanksCard: 'c' * 64,
  );

  @override
  Stream<StampRallyCard> watchCard(String uid) => throw UnimplementedError();

  @override
  Future<StampRallyScanResult> scan(String token) => throw UnimplementedError();
}
