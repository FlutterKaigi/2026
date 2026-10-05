import 'package:dashboard/core/env.dart';
import 'package:dashboard/core/event_environment/event_admin_client.dart';
import 'package:dashboard/feature/auth/data/provider/auth_state.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final supportLtRepositoryProvider = Provider<SupportLtRepository>(
  (_) => FirebaseSupportLtRepository(),
);

/// Origin of the attendee app that talks to the operated environment, so the
/// attendance QR code opens the app that can verify its code.
///
/// The local emulator, and a page outside an operated environment, have no
/// such app: `null` keeps the QR code a bare code instead of linking to a
/// live app.
final supportLtAppOriginProvider = Provider<String?>(
  (ref) => switch (ref.watch(eventAdminClientProvider)?.environment) {
    Flavor.prod => productionAppOrigin,
    Flavor.stg => stagingAppOrigin,
    Flavor.dev || null => null,
  },
);

final supportLtCodeProvider = StreamProvider.autoDispose<SupportLtCode?>(
  (ref) {
    final uid = ref.watch(authStateProvider.select((auth) => auth.asData?.value?.uid));
    return uid == null ? Stream.value(null) : ref.watch(supportLtRepositoryProvider).watchCode();
  },
  retry: (_, _) => null,
);

final supportLtRegistrationsProvider = StreamProvider.autoDispose<List<SupportLtRegistration>>(
  (ref) {
    final uid = ref.watch(authStateProvider.select((auth) => auth.asData?.value?.uid));
    return uid == null ? Stream.value(const []) : ref.watch(supportLtRepositoryProvider).watchRegistrations();
  },
  retry: (_, _) => null,
);
