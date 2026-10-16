import 'package:app/core/log/talker.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/event_guide/data/event_guide_seen_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  late Talker talker;

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
  });

  ProviderContainer containerWith(SharedPreferences preferences) {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        talkerProvider.overrideWithValue(talker),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('is false until the guide has opened by itself', () async {
    final container = containerWith(await SharedPreferences.getInstance());

    expect(container.read(eventGuideSeenProvider), isFalse);
  });

  test('stays true after the app restarts', () async {
    final container = containerWith(await SharedPreferences.getInstance());

    await container.read(eventGuideSeenProvider.notifier).markSeen();
    expect(container.read(eventGuideSeenProvider), isTrue);

    SharedPreferences.resetStatic();
    final restarted = containerWith(await SharedPreferences.getInstance());
    expect(restarted.read(eventGuideSeenProvider), isTrue);
  });

  test('stays true for this run and logs when the save fails', () async {
    final container = containerWith(_UnsavablePreferences());

    await container.read(eventGuideSeenProvider.notifier).markSeen();

    expect(container.read(eventGuideSeenProvider), isTrue);
    expect(talker.history.map((log) => log.message), contains('Could not save that the day-of guide was shown'));
  });
}

final class _UnsavablePreferences extends Fake implements SharedPreferences {
  @override
  bool? getBool(String key) => null;

  @override
  Future<bool> setBool(String key, bool value) async => false;
}
