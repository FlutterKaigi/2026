import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  FirebaseStampRallyRepository repository([Object? result]) => FirebaseStampRallyRepository(
    firestore: firestore,
    functions: _StubFunctions(result: result),
  );

  test('settings fall back to the defaults until configured', () async {
    final settings = await repository().watchSettings().first;
    expect(settings.checkpoints, [7, 14, 22]);
    expect(settings.isOpen, isFalse);

    await firestore.doc('stampRallySettings/current').set({
      'checkpoints': [3, 5],
      'isOpen': true,
    });
    final configured = await repository().watchSettings().first;
    expect(configured.checkpoints, [3, 5]);
    expect(configured.isOpen, isTrue);
  });

  test('cards parse stamps, numbered redemptions, and the thanks card', () async {
    expect((await repository().watchCard('attendee').first).stampCount, 0);

    final at = DateTime.utc(2026, 11, 13, 10);
    await firestore.doc('stampRallyCards/attendee').set({
      'stamps': {'sponsor-a': Timestamp.fromDate(at), 'sponsor-b': Timestamp.fromDate(at)},
      'rewardsRedeemedAt': {'1': Timestamp.fromDate(at)},
      'thanksCardRedeemedAt': Timestamp.fromDate(at),
    });
    final card = await repository().watchCard('attendee').first;

    expect(card.stamps.keys, unorderedEquals(['sponsor-a', 'sponsor-b']));
    expect(card.rewardsRedeemedAt.keys, [1]);
    expect(card.thanksCardRedeemedAt?.isAtSameMomentAs(at), isTrue);
    expect(card.achievedCheckpoints([2, 3]), [1]);
  });

  test('sponsor membership is written and removed by document', () async {
    await repository().setSponsorEnabled('sponsor-a', enabled: true);
    expect(await repository().watchSponsorIds().first, {'sponsor-a'});
    await repository().setSponsorEnabled('sponsor-a', enabled: false);
    expect((await firestore.collection('stampRallySponsors').get()).docs, isEmpty);
  });

  test('scan results are parsed by kind', () async {
    final stamp = await repository({
      'kind': 'stamp',
      'sponsorId': 'sponsor-a',
      'alreadyAcquired': false,
      'acquiredAt': 1000,
      'stampCount': 7,
      'newCheckpoints': [1],
      'checkpoints': [7, 14, 22],
    }).scan('token');
    expect(stamp, isA<StampRallyStampResult>().having((result) => result.newCheckpoints, 'newCheckpoints', [1]));

    final reward = await repository({
      'kind': 'reward',
      'redeemedCheckpoints': [1, 2],
      'redeemedAt': 2000,
      'stampCount': 14,
      'checkpoints': [7, 14, 22],
      'rewardsRedeemedAt': {'1': 2000, '2': 2000},
    }).scan('token');
    expect(
      reward,
      isA<StampRallyRewardResult>()
          .having((result) => result.redeemedCheckpoints, 'redeemedCheckpoints', [1, 2])
          .having((result) => result.rewardsRedeemedAt.keys, 'rewardsRedeemedAt', [1, 2]),
    );

    final thanks = await repository({'kind': 'thanksCard', 'alreadyRedeemed': true, 'redeemedAt': 3000}).scan('t');
    expect(thanks, isA<StampRallyThanksCardResult>().having((result) => result.alreadyRedeemed, 'already', isTrue));
  });
}

class _StubFunctions extends Fake implements FirebaseFunctions {
  _StubFunctions({this.result});

  final Object? result;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) => _StubCallable(result);
}

class _StubCallable extends Fake implements HttpsCallable {
  _StubCallable(this.result);

  final Object? result;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async => _StubCallableResult<T>(result as T);
}

class _StubCallableResult<T> extends Fake implements HttpsCallableResult<T> {
  _StubCallableResult(this.data);

  @override
  final T data;
}
