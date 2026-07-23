import 'package:app/feature/sponsor/data/provider/sponsor_repository.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Streams sponsors from Firestore.
final sponsorListProvider = StreamProvider<List<Sponsor>>(
  (ref) => ref.watch(sponsorRepositoryProvider).watchAll(),
);

/// Groups sponsors for the logo wall UI.
final sponsorWallProvider = Provider<AsyncValue<SponsorWallData>>(
  (ref) => ref.watch(sponsorListProvider).whenData(buildSponsorWallData),
);

/// Builds sponsor wall data from the raw Firestore sponsor list.
SponsorWallData buildSponsorWallData(List<Sponsor> sponsors) {
  final ordered = [...sponsors]..sort(_compareSponsors);
  final groups = <SponsorTierGroup>[];

  for (final tier in SponsorTier.values) {
    final sponsorsInTier = [
      for (final sponsor in ordered)
        if (sponsor.tier == tier) sponsor,
    ];
    if (sponsorsInTier.isNotEmpty) {
      groups.add(SponsorTierGroup(tier: tier, sponsors: sponsorsInTier));
    }
  }

  return SponsorWallData(groups: groups);
}

int _compareSponsors(Sponsor a, Sponsor b) {
  final tierCompare = SponsorTier.values
      .indexOf(a.tier)
      .compareTo(
        SponsorTier.values.indexOf(b.tier),
      );
  if (tierCompare != 0) {
    return tierCompare;
  }

  final pinnedCompare = _pinnedSortValue(a).compareTo(_pinnedSortValue(b));
  if (pinnedCompare != 0) {
    return pinnedCompare;
  }

  return a.id.compareTo(b.id);
}

int _pinnedSortValue(Sponsor sponsor) {
  if (sponsor.id == 'D2026-015' || sponsor.slug == 'flutter') {
    return 0;
  }
  return 1;
}

/// Sponsor groups in display order.
final class SponsorWallData {
  const SponsorWallData({required this.groups});

  final List<SponsorTierGroup> groups;

  bool get isEmpty => groups.isEmpty;
}

/// Sponsors for one sponsorship tier.
final class SponsorTierGroup {
  const SponsorTierGroup({
    required this.tier,
    required this.sponsors,
  });

  final SponsorTier tier;
  final List<Sponsor> sponsors;
}
