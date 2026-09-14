import 'package:app/feature/staff/ui/widget/staff_member_card_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses dedicated icons for supported services', (tester) async {
    await _pumpCard(tester, const [
      SnsLink(type: 'x', value: 'https://x.com/flutterkaigi'),
      SnsLink(type: 'github', value: 'https://github.com/FlutterKaigi'),
      SnsLink(type: 'note', value: 'https://note.com/flutterkaigi'),
      SnsLink(type: 'medium', value: 'https://medium.com/@flutterkaigi'),
      SnsLink(type: 'bluesky', value: 'https://bsky.app/profile/flutterkaigi'),
      SnsLink(type: 'qiita', value: 'https://qiita.com/flutterkaigi'),
      SnsLink(type: 'zenn', value: 'https://zenn.dev/flutterkaigi'),
    ]);

    expect(_svgAssetNames(tester), [
      'res/assets/icons/link_x.svg',
      'res/assets/icons/link_github.svg',
      'res/assets/icons/link_note.svg',
      'res/assets/icons/link_medium.svg',
      'res/assets/icons/link_bluesky.svg',
      'res/assets/icons/link_qiita.svg',
      'res/assets/icons/link_zenn.svg',
    ]);
  });

  testWidgets('uses the png brand mark for mixi2', (tester) async {
    await _pumpCard(tester, const [
      SnsLink(type: 'mixi2', value: 'https://mixi.social/@flutterkaigi'),
    ]);

    // 公式が svg を配布していないため mixi2 だけ png
    expect(find.byType(SvgPicture), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'res/assets/icons/link_mixi2.png');
  });

  testWidgets('uses the common web icon for unknown services', (tester) async {
    await _pumpCard(tester, const [
      SnsLink(type: 'web', value: 'https://flutterkaigi.jp'),
      SnsLink(type: 'custom', value: 'https://example.com'),
    ]);

    expect(_svgAssetNames(tester), [
      'res/assets/icons/link_globe.svg',
      'res/assets/icons/link_globe.svg',
    ]);
  });

  testWidgets('matches service keys without case sensitivity', (tester) async {
    await _pumpCard(tester, const [
      SnsLink(type: 'BlueSky', value: 'https://bsky.app/profile/flutterkaigi'),
      SnsLink(type: 'QIITA', value: 'https://qiita.com/flutterkaigi'),
      SnsLink(type: 'Twitter', value: 'https://twitter.com/flutterkaigi'),
    ]);

    expect(_svgAssetNames(tester), [
      'res/assets/icons/link_bluesky.svg',
      'res/assets/icons/link_qiita.svg',
      'res/assets/icons/link_x.svg',
    ]);
  });

  testWidgets('labels each icon button with its platform name', (tester) async {
    await _pumpCard(tester, const [
      SnsLink(type: 'zenn', value: 'https://zenn.dev/flutterkaigi'),
      SnsLink(type: 'custom', value: 'https://example.com'),
    ]);

    expect(
      tester.widgetList<IconButton>(find.byType(IconButton)).map((button) => button.tooltip),
      ['Zenn', 'Web'],
    );
  });
}

Future<void> _pumpCard(WidgetTester tester, List<SnsLink> snsLinks) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StaffMemberCardWidget(
          staffMember: StaffMember(
            id: 'staff-001',
            name: '運営 太郎',
            iconUrl: '',
            snsLinks: snsLinks,
            order: 1,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _svgAssetNames(WidgetTester tester) => tester
    .widgetList<SvgPicture>(find.byType(SvgPicture))
    .map((svg) => (svg.bytesLoader as SvgAssetLoader).assetName)
    .toList();
