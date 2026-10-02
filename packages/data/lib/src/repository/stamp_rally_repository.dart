import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../model/stamp_rally.dart';
import 'firestore_watch.dart';

abstract interface class StampRallyRepository {
  /// Emits [StampRallySettings.defaults] until the settings document exists.
  Stream<StampRallySettings> watchSettings();

  /// Emits the IDs of the sponsors handing out stamps.
  Stream<Set<String>> watchSponsorIds();

  /// Emits [StampRallyCard.empty] until the attendee's first scan.
  Stream<StampRallyCard> watchCard(String uid);

  /// Sends a scanned token to the server, which decides its purpose from the
  /// signature. Preserves [FirebaseFunctionsException] failures.
  Future<StampRallyScanResult> scan(String token);

  /// Adds or removes a stamp sponsor. Requires admin access.
  Future<void> setSponsorEnabled(String sponsorId, {required bool enabled});

  /// Requires admin access.
  Future<void> saveSettings(StampRallySettings settings);

  /// Requires admin access.
  Future<StampRallyQrCodes> fetchQrCodes();
}

final class FirebaseStampRallyRepository implements StampRallyRepository {
  FirebaseStampRallyRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  DocumentReference<Map<String, dynamic>> get _settings => _firestore.collection('stampRallySettings').doc('current');

  CollectionReference<Map<String, dynamic>> get _sponsors => _firestore.collection('stampRallySponsors');

  @override
  Stream<StampRallySettings> watchSettings() => watchFirestoreDocument(_settings).map((snapshot) {
    final data = snapshot.data();
    if (data == null) {
      return StampRallySettings.defaults;
    }
    final checkpoints = data['checkpoints'];
    final isOpen = data['isOpen'];
    if (checkpoints is! List || checkpoints.any((value) => value is! int) || isOpen is! bool) {
      throw const FormatException('Invalid stamp rally settings.');
    }
    return StampRallySettings(checkpoints: List.unmodifiable(checkpoints.cast<int>()), isOpen: isOpen);
  });

  @override
  Stream<Set<String>> watchSponsorIds() =>
      watchFirestoreQuery(_sponsors).map((snapshot) => Set.unmodifiable(snapshot.docs.map((document) => document.id)));

  @override
  Stream<StampRallyCard> watchCard(String uid) =>
      watchFirestoreDocument(_firestore.collection('stampRallyCards').doc(uid)).map((snapshot) {
        final data = snapshot.data();
        if (data == null) {
          return StampRallyCard.empty;
        }
        final thanksCardRedeemedAt = data['thanksCardRedeemedAt'];
        return StampRallyCard(
          stamps: _timestamps(data['stamps'], (key) => key),
          rewardsRedeemedAt: _timestamps(data['rewardsRedeemedAt'], int.parse),
          thanksCardRedeemedAt: thanksCardRedeemedAt == null ? null : _timestamp(thanksCardRedeemedAt),
        );
      });

  @override
  Future<StampRallyScanResult> scan(String token) async {
    final result = await _functions.httpsCallable('scanStampRallyCode').call<Object?>({'token': token});
    final data = _map(result.data);
    return switch (data['kind']) {
      'stamp' => StampRallyStampResult(
        sponsorId: data['sponsorId']! as String,
        alreadyAcquired: data['alreadyAcquired']! as bool,
        acquiredAt: _millis(data['acquiredAt']),
        stampCount: data['stampCount']! as int,
        newCheckpoints: _ints(data['newCheckpoints']),
        checkpoints: _ints(data['checkpoints']),
      ),
      'reward' => StampRallyRewardResult(
        redeemedCheckpoints: _ints(data['redeemedCheckpoints']),
        redeemedAt: data['redeemedAt'] == null ? null : _millis(data['redeemedAt']),
        stampCount: data['stampCount']! as int,
        checkpoints: _ints(data['checkpoints']),
        rewardsRedeemedAt: {
          for (final MapEntry(:key, :value) in _map(data['rewardsRedeemedAt']).entries) int.parse(key): _millis(value),
        },
      ),
      'thanksCard' => StampRallyThanksCardResult(
        alreadyRedeemed: data['alreadyRedeemed']! as bool,
        redeemedAt: _millis(data['redeemedAt']),
      ),
      _ => throw const FormatException('Unknown stamp rally scan result.'),
    };
  }

  @override
  Future<void> setSponsorEnabled(String sponsorId, {required bool enabled}) => enabled
      ? _sponsors.doc(sponsorId).set({'createdAt': FieldValue.serverTimestamp()})
      : _sponsors.doc(sponsorId).delete();

  @override
  Future<void> saveSettings(StampRallySettings settings) => _settings.set({
    'checkpoints': settings.checkpoints,
    'isOpen': settings.isOpen,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<StampRallyQrCodes> fetchQrCodes() async {
    final result = await _functions.httpsCallable('getStampRallyQrCodes').call<Object?>({});
    final data = _map(result.data);
    return StampRallyQrCodes(
      sponsors: [
        for (final sponsor in data['sponsors']! as List<Object?>)
          (sponsorId: _map(sponsor)['sponsorId']! as String, token: _map(sponsor)['token']! as String),
      ],
      reward: data['reward']! as String,
      thanksCard: data['thanksCard']! as String,
    );
  }

  // Callable results arrive as Map<Object?, Object?> on native platforms.
  static Map<String, Object?> _map(Object? value) => (value! as Map<Object?, Object?>).cast<String, Object?>();

  static List<int> _ints(Object? value) => List.unmodifiable((value! as List<Object?>).cast<int>());

  static DateTime _millis(Object? value) => DateTime.fromMillisecondsSinceEpoch((value! as num).toInt());

  static Map<K, DateTime> _timestamps<K>(Object? value, K Function(String key) parseKey) {
    if (value == null) {
      return const {};
    }
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a map of timestamps.');
    }
    return Map.unmodifiable({for (final MapEntry(:key, :value) in value.entries) parseKey(key): _timestamp(value)});
  }

  static DateTime _timestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    throw const FormatException('Expected a Firestore timestamp.');
  }
}
