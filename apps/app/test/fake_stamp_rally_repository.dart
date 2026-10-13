import 'package:data/data.dart';

final class FakeStampRallyRepository implements StampRallyRepository {
  FakeStampRallyRepository({
    this.settings = const StampRallySettings(checkpoints: [1, 2], isOpen: true),
    this.sponsorIds = const {},
    this.card = StampRallyCard.empty,
  });

  StampRallySettings settings;
  Set<String> sponsorIds;
  StampRallyCard card;
  final scannedTokens = <String>[];
  StampRallyScanResult? scanResult;
  Exception? scanError;

  @override
  Stream<StampRallySettings> watchSettings() => Stream.value(settings);

  @override
  Stream<Set<String>> watchSponsorIds() => Stream.value(sponsorIds);

  @override
  Stream<StampRallyCard> watchCard(String uid) => Stream.value(card);

  @override
  Future<StampRallyScanResult> scan(String token) async {
    scannedTokens.add(token);
    if (scanError case final error?) {
      throw error;
    }
    return scanResult!;
  }

  @override
  Future<void> setSponsorEnabled(String sponsorId, {required bool enabled}) => throw UnimplementedError();

  @override
  Future<void> saveSettings(StampRallySettings settings) => throw UnimplementedError();

  @override
  Future<StampRallyQrCodes> fetchQrCodes() => throw UnimplementedError();
}
