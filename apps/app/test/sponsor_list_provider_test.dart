import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildSponsorWallData groups sponsors by tier and pins Flutter first', () {
    final data = buildSponsorWallData([
      _sponsor(id: 'D2026-030', name: 'Gold B', tier: SponsorTier.gold),
      _sponsor(id: 'D2026-016', name: 'Platinum B'),
      _sponsor(id: 'D2026-015', name: 'Flutter', slug: 'flutter'),
      _sponsor(id: 'D2026-010', name: 'Gold A', tier: SponsorTier.gold),
    ]);

    expect(data.groups.map((group) => group.tier), [
      SponsorTier.platinum,
      SponsorTier.gold,
    ]);
    expect(data.groups.first.sponsors.map((sponsor) => sponsor.id), [
      'D2026-015',
      'D2026-016',
    ]);
    expect(data.groups.last.sponsors.map((sponsor) => sponsor.id), [
      'D2026-010',
      'D2026-030',
    ]);
  });
}

Sponsor _sponsor({
  required String id,
  required String name,
  SponsorTier tier = SponsorTier.platinum,
  String? slug,
}) {
  return Sponsor(
    id: id,
    name: LocaleMap(ja: name, en: name),
    description: const LocaleMap(ja: '', en: ''),
    tier: tier,
    slug: slug,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}
