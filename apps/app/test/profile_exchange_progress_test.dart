import 'package:app/feature/mission/data/profile_exchange_progress.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProfileExchangeProgress evaluate(List<UserProfile?> others, {UserProfile? self}) =>
      ProfileExchangeProgress.evaluate(uid: 'me', profile: self ?? profile('me', 'JP'), exchangedProfiles: others);

  test('requires three distinct people and at least one different country', () {
    expect(evaluate([]).isComplete, isFalse);
    expect(evaluate([profile('a', 'US'), profile('b', 'JP')]).isComplete, isFalse);
    expect(evaluate([profile('a', 'JP'), profile('b', 'JP'), profile('c', 'JP')]).isComplete, isFalse);
    expect(evaluate([profile('a', 'JP'), profile('b', 'US'), profile('c', 'JP')]).isComplete, isTrue);
    expect(evaluate([profile('a', 'US'), profile('b', 'US'), profile('c', 'US')]).isComplete, isTrue);
  });

  test('never counts self, duplicates or deleted profiles', () {
    final result = evaluate([profile('me', 'JP'), profile('a', 'US'), profile('a', 'US'), null, profile('b', 'JP')]);
    expect(result.count, 2);
    expect(result.hasDifferentCountry, isTrue);
    expect(result.isComplete, isFalse);
  });

  test('missing own profile cannot meet the country condition', () {
    final result = ProfileExchangeProgress.evaluate(
      uid: 'me',
      profile: null,
      exchangedProfiles: [profile('a', 'US'), profile('b', 'JP'), profile('c', 'JP')],
    );
    expect(result.hasProfile, isFalse);
    expect(result.hasDifferentCountry, isFalse);
    expect(result.isComplete, isFalse);
  });

  test('invalid country data cannot meet the different-country condition', () {
    expect(evaluate([profile('a', 'ZZ'), profile('b', 'JP'), profile('c', 'JP')]).isComplete, isFalse);
    expect(evaluate([profile('a', 'US')], self: profile('me', 'ZZ')).hasDifferentCountry, isFalse);
  });
}

UserProfile profile(String uid, String country) => UserProfile(
  id: uid,
  displayName: uid,
  countryOrRegion: country,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
