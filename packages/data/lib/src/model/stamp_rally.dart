/// Stamp rally configuration at `stampRallySettings/current`.
final class StampRallySettings {
  const StampRallySettings({required this.checkpoints, required this.isOpen});

  /// Served while `stampRallySettings/current` does not exist yet.
  static const defaults = StampRallySettings(checkpoints: [7, 14, 22], isOpen: false);

  /// Stamps required for each prize. The position is the prize number (#1, #2, …).
  final List<int> checkpoints;

  /// Whether new stamps are accepted. Prize and thanks-card redemption ignore it.
  final bool isOpen;
}

/// An attendee's stamps and redemptions at `stampRallyCards/{uid}`.
final class StampRallyCard {
  const StampRallyCard({required this.stamps, required this.rewardsRedeemedAt, this.thanksCardRedeemedAt});

  static const empty = StampRallyCard(stamps: {}, rewardsRedeemedAt: {});

  /// Acquisition time keyed by sponsor ID.
  final Map<String, DateTime> stamps;

  /// Redemption time keyed by 1-based checkpoint number.
  final Map<int, DateTime> rewardsRedeemedAt;

  final DateTime? thanksCardRedeemedAt;

  int get stampCount => stamps.length;

  /// 1-based numbers of the checkpoints reached with the current stamps.
  List<int> achievedCheckpoints(List<int> checkpoints) => [
    for (var index = 0; index < checkpoints.length; index++)
      if (stampCount >= checkpoints[index]) index + 1,
  ];
}

/// Tokens for printing the stamp rally QR codes.
final class StampRallyQrCodes {
  const StampRallyQrCodes({required this.sponsors, required this.reward, required this.thanksCard});

  final List<({String sponsorId, String token})> sponsors;
  final String reward;
  final String thanksCard;
}

/// What `scanStampRallyCode` did for the scanned token.
sealed class StampRallyScanResult {
  const StampRallyScanResult();
}

final class StampRallyStampResult extends StampRallyScanResult {
  const StampRallyStampResult({
    required this.sponsorId,
    required this.alreadyAcquired,
    required this.acquiredAt,
    required this.stampCount,
    required this.newCheckpoints,
    required this.checkpoints,
  });

  final String sponsorId;
  final bool alreadyAcquired;
  final DateTime acquiredAt;
  final int stampCount;

  /// 1-based checkpoint numbers reached by this stamp.
  final List<int> newCheckpoints;
  final List<int> checkpoints;
}

final class StampRallyRewardResult extends StampRallyScanResult {
  const StampRallyRewardResult({
    required this.redeemedCheckpoints,
    required this.redeemedAt,
    required this.stampCount,
    required this.checkpoints,
    required this.rewardsRedeemedAt,
  });

  /// 1-based checkpoint numbers redeemed by this scan; empty when nothing was left.
  final List<int> redeemedCheckpoints;
  final DateTime? redeemedAt;
  final int stampCount;
  final List<int> checkpoints;

  /// Every redemption so far, including [redeemedCheckpoints].
  final Map<int, DateTime> rewardsRedeemedAt;
}

final class StampRallyThanksCardResult extends StampRallyScanResult {
  const StampRallyThanksCardResult({required this.alreadyRedeemed, required this.redeemedAt});

  final bool alreadyRedeemed;
  final DateTime redeemedAt;
}
