import 'package:app/core/log/talker.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EventGuideSeenNotifier extends Notifier<bool> {
  static const preferencesKey = 'event_day_guide_2026_seen';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(preferencesKey) ?? false;

  Future<void> markSeen() async {
    state = true;
    final talker = ref.read(talkerProvider);
    try {
      final saved = await ref.read(sharedPreferencesProvider).setBool(preferencesKey, true);
      if (!saved) {
        talker.warning('Could not save that the day-of guide was shown');
      }
    } on Exception catch (error, stackTrace) {
      talker.handle(error, stackTrace, 'Could not save that the day-of guide was shown');
    }
  }
}

final eventGuideSeenProvider = NotifierProvider<EventGuideSeenNotifier, bool>(EventGuideSeenNotifier.new);
