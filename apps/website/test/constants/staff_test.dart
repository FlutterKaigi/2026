import 'package:test/test.dart';
import 'package:website/constants/staff.dart';

void main() {
  group('StaffSnsLink.iconAsset', () {
    test('uses dedicated icons for supported services', () {
      expect(_link('bluesky').iconAsset, 'images/icons/link_bluesky.svg');
      expect(_link('qiita').iconAsset, 'images/icons/link_qiita.svg');
      expect(_link('zenn').iconAsset, 'images/icons/link_zenn.svg');
    });

    test('uses the common web icon for mixi2 and unknown services', () {
      expect(_link('mixi2').iconAsset, 'images/icons/link_globe.svg');
      expect(_link('web').iconAsset, 'images/icons/link_globe.svg');
      expect(_link('custom').iconAsset, 'images/icons/link_globe.svg');
    });

    test('matches service keys without case sensitivity', () {
      expect(_link('BlueSky').iconAsset, 'images/icons/link_bluesky.svg');
      expect(_link('QIITA').iconAsset, 'images/icons/link_qiita.svg');
      expect(_link('Zenn').iconAsset, 'images/icons/link_zenn.svg');
    });
  });
}

StaffSnsLink _link(String type) => StaffSnsLink(
  type: type,
  value: 'https://example.com',
);
