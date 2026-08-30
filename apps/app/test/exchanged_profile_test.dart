import 'dart:async';

import 'package:app/feature/exchange/data/exchanged_profile.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProfileExchange exchange(String otherUid) =>
      ProfileExchange(id: otherUid, createdAt: DateTime.utc(2026), origin: ProfileExchangeOrigin.scan);

  UserProfile profile(String id, {String displayName = 'Attendee'}) => UserProfile(
    id: id,
    displayName: displayName,
    countryOrRegion: 'JP',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  test('joins each exchange with its profile stream', () async {
    final exchangesController = StreamController<List<ProfileExchange>>();
    final profileControllers = <String, StreamController<UserProfile?>>{
      'uid-a': StreamController<UserProfile?>(),
      'uid-b': StreamController<UserProfile?>(),
    };
    addTearDown(exchangesController.close);
    addTearDown(() async {
      for (final controller in profileControllers.values) {
        await controller.close();
      }
    });

    final results = <List<ExchangedProfile>>[];
    final subscription = watchExchangedProfiles(
      exchanges: exchangesController.stream,
      profileFor: (uid) => profileControllers[uid]!.stream,
    ).listen(results.add);
    addTearDown(subscription.cancel);

    exchangesController.add([exchange('uid-a'), exchange('uid-b')]);
    await Future<void>.delayed(Duration.zero);
    // 各プロフィールが届くまでエントリは表示されない。
    expect(results.last, isEmpty);

    profileControllers['uid-a']!.add(profile('uid-a', displayName: 'Alice'));
    await Future<void>.delayed(Duration.zero);
    expect(results.last.map((e) => e.otherUid), ['uid-a']);

    profileControllers['uid-b']!.add(profile('uid-b', displayName: 'Bob'));
    await Future<void>.delayed(Duration.zero);
    expect(results.last.map((e) => e.otherUid).toSet(), {'uid-a', 'uid-b'});
    expect(results.last.firstWhere((e) => e.otherUid == 'uid-b').profile?.displayName, 'Bob');
  });

  test('shows a deleted profile as null once its stream confirms it', () async {
    final exchangesController = StreamController<List<ProfileExchange>>();
    final profileController = StreamController<UserProfile?>();
    addTearDown(exchangesController.close);
    addTearDown(profileController.close);

    final results = <List<ExchangedProfile>>[];
    final subscription = watchExchangedProfiles(
      exchanges: exchangesController.stream,
      profileFor: (uid) => profileController.stream,
    ).listen(results.add);
    addTearDown(subscription.cancel);

    exchangesController.add([exchange('uid-a')]);
    profileController.add(profile('uid-a'));
    await Future<void>.delayed(Duration.zero);
    expect(results.last.single.profile, isNotNull);

    // 相手がプロフィールを削除すると null が届く。
    profileController.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(results.last.single.profile, isNull);
  });

  test('drops the profile subscription when an exchange is removed', () async {
    final exchangesController = StreamController<List<ProfileExchange>>();
    var subscribeCount = 0;
    var cancelCount = 0;
    final profileController = StreamController<UserProfile?>.broadcast(
      onListen: () => subscribeCount++,
      onCancel: () => cancelCount++,
    );
    addTearDown(exchangesController.close);
    addTearDown(profileController.close);

    final results = <List<ExchangedProfile>>[];
    final subscription = watchExchangedProfiles(
      exchanges: exchangesController.stream,
      profileFor: (uid) => profileController.stream,
    ).listen(results.add);
    addTearDown(subscription.cancel);

    exchangesController.add([exchange('uid-a')]);
    await Future<void>.delayed(Duration.zero);
    expect(subscribeCount, 1);

    exchangesController.add(const []);
    await Future<void>.delayed(Duration.zero);
    expect(cancelCount, 1);
    expect(results.last, isEmpty);
  });
}
