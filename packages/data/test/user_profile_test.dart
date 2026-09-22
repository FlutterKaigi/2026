import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips through JSON with Firestore-style values', () {
    final profile = UserProfile.fromJson({
      'id': 'uid-1',
      'displayName': 'Yuhei',
      'avatarUrl': 'https://example.com/avatar.png',
      'countryOrRegion': 'JP',
      'snsLinks': [
        {'type': 'x', 'value': 'https://x.com/yuhei'},
      ],
      'bio': 'Hello',
      'createdAt': '2026-08-01T00:00:00Z',
      'updatedAt': '2026-08-02T00:00:00Z',
    });

    expect(profile.id, 'uid-1');
    expect(profile.displayName, 'Yuhei');
    expect(profile.avatarUrl, 'https://example.com/avatar.png');
    expect(profile.countryOrRegion, 'JP');
    expect(profile.snsLinks, [const SnsLink(type: 'x', value: 'https://x.com/yuhei')]);
    expect(profile.bio, 'Hello');
    expect(profile.createdAt, DateTime.utc(2026, 8, 1));
    expect(profile.updatedAt, DateTime.utc(2026, 8, 2));

    final json = profile.toJson();
    expect(json['snsLinks'], [
      {'type': 'x', 'value': 'https://x.com/yuhei'},
    ]);
    expect(json['createdAt'], DateTime.utc(2026, 8, 1));
  });

  test('defaults snsLinks to an empty list when the field is absent', () {
    final profile = UserProfile.fromJson({
      'id': 'uid-2',
      'displayName': 'Jane',
      'countryOrRegion': 'US',
      'createdAt': '2026-08-01T00:00:00Z',
      'updatedAt': '2026-08-01T00:00:00Z',
    });
    expect(profile.snsLinks, isEmpty);
    expect(profile.avatarUrl, isNull);
    expect(profile.bio, isNull);
  });
}
