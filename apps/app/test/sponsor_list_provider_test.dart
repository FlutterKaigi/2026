import 'package:app/feature/sponsor/data/provider/sponsor_detail_provider.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_repository.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('sponsorListProvider keeps logo-less sponsors and excludes unsupported tiers', () async {
    final repository = _FakeSponsorRepository([
      _sponsor(id: 'with-logo', name: 'With Logo'),
      _sponsor(id: 'without-logo', name: 'Without Logo', primaryLogoUrl: null),
    ]);
    final container = ProviderContainer(
      overrides: [
        sponsorRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(sponsorListProvider, (_, _) {});
    addTearDown(subscription.close);

    final sponsors = await container.read(sponsorListProvider.future);

    expect(sponsors.map((sponsor) => sponsor.id), ['with-logo', 'without-logo']);
    expect(repository.excludeUnsupportedTiers, isTrue);
  });

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

  test('findSponsorByRouteKey resolves sponsors by slug and ID', () {
    final sponsors = [
      _sponsor(id: 'D2026-020', name: 'CyberAgent', slug: 'cyberagent'),
      _sponsor(id: 'D2026-021', name: 'No Slug'),
    ];

    expect(findSponsorByRouteKey(sponsors, 'cyberagent')?.id, 'D2026-020');
    expect(findSponsorByRouteKey(sponsors, 'D2026-021')?.id, 'D2026-021');
    expect(findSponsorByRouteKey(sponsors, 'missing'), isNull);
  });
}

final class _FakeSponsorRepository implements SponsorRepository {
  _FakeSponsorRepository(this.sponsors);

  final List<Sponsor> sponsors;
  bool? excludeUnsupportedTiers;

  @override
  Stream<List<Sponsor>> watchAll({bool excludeUnsupportedTiers = false}) {
    this.excludeUnsupportedTiers = excludeUnsupportedTiers;
    return Stream.value(sponsors);
  }

  @override
  Future<void> save(Sponsor sponsor) async {}

  @override
  Future<void> delete(String id) async {}
}

Sponsor _sponsor({
  required String id,
  required String name,
  SponsorTier tier = SponsorTier.platinum,
  String? slug,
  String? primaryLogoUrl = 'https://example.com/logo.png',
}) {
  return Sponsor(
    id: id,
    name: LocaleMap(ja: name, en: name),
    description: const LocaleMap(ja: '', en: ''),
    tier: tier,
    slug: slug,
    primaryLogoUrl: primaryLogoUrl,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}
