import 'package:app/core/provider/environment.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Region every profile-exchange callable is deployed to. Must match
/// `functions/src/region.ts`'s `REGION`.
const exchangeFunctionsRegion = 'asia-northeast1';

/// Provides the [FirebaseFunctions] instance used by the profile-exchange
/// callables, routed to the local Emulator Suite in develop (mirroring
/// `apps/dashboard/lib/core/sync/collection_sync_service.dart`).
final exchangeFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  final environment = ref.watch(environmentProvider);
  final functions = FirebaseFunctions.instanceFor(region: exchangeFunctionsRegion);
  if (environment.flavor == Flavor.develop) {
    final host = environment.firestoreHost.split(':').first;
    functions.useFunctionsEmulator(host, 5001);
  }
  return functions;
});
