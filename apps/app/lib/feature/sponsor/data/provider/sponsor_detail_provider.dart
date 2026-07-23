import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Finds one sponsor from the same list stream used by the sponsor wall.
final sponsorDetailProvider = Provider.family<AsyncValue<Sponsor?>, String>(
  (ref, sponsorKey) {
    return ref
        .watch(sponsorListProvider)
        .whenData(
          (sponsors) => findSponsorByRouteKey(sponsors, sponsorKey),
        );
  },
);

Sponsor? findSponsorByRouteKey(List<Sponsor> sponsors, String sponsorKey) {
  final key = sponsorKey.trim();
  for (final sponsor in sponsors) {
    if (sponsorRouteKey(sponsor) == key || sponsor.id == key) {
      return sponsor;
    }
  }
  return null;
}

String sponsorRouteKey(Sponsor sponsor) {
  final slug = sponsor.slug?.trim();
  if (slug != null && slug.isNotEmpty) {
    return slug;
  }
  return sponsor.id;
}
