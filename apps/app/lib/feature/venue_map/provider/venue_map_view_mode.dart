import 'package:app/core/provider/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum VenueMapViewMode { twoD, threeD }

class VenueMapViewModeNotifier extends Notifier<VenueMapViewMode> {
  static const preferencesKey = 'venue_map_view_mode';

  @override
  VenueMapViewMode build() {
    final value = ref.watch(sharedPreferencesProvider).getString(preferencesKey);
    return VenueMapViewMode.values.asNameMap()[value] ?? VenueMapViewMode.twoD;
  }

  Future<void> set(VenueMapViewMode mode) async {
    final saved = await ref.read(sharedPreferencesProvider).setString(preferencesKey, mode.name);
    if (!saved) {
      throw StateError('Could not persist the venue map view.');
    }
    state = mode;
  }
}

final venueMapViewModeProvider = NotifierProvider<VenueMapViewModeNotifier, VenueMapViewMode>(
  VenueMapViewModeNotifier.new,
);
