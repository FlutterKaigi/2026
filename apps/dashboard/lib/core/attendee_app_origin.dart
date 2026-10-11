import 'package:dashboard/core/env.dart';
import 'package:dashboard/core/event_environment/event_admin_client.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Origin of the attendee app that talks to the operated environment, so a
/// venue QR code (Support LT attendance, quiz check-in) opens the app that can
/// verify its code.
///
/// The local emulator, and a page outside an operated environment, have no
/// such app: `null` keeps the QR code a bare code instead of linking to a
/// live app.
final attendeeAppOriginProvider = Provider<String?>(
  (ref) => switch (ref.watch(eventAdminClientProvider)?.environment) {
    Flavor.prod => productionAppOrigin,
    Flavor.stg => stagingAppOrigin,
    Flavor.dev || null => null,
  },
);
