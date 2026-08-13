import 'package:flutter/widgets.dart';
import 'package:venue_screen/core/config/venue_screen_config.dart';
import 'package:venue_screen/feature/caption/data/caption_socket.dart';
import 'package:venue_screen/feature/caption/provider/caption_overlay_controller.dart';
import 'package:venue_screen/feature/caption/ui/page/venue_screen_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = VenueScreenConfig.fromUri(Uri.base);
  runApp(
    VenueScreenApp(
      config: config,
      controller: CaptionOverlayController(
        config: config,
        connector: const WebSocketCaptionConnector(),
      ),
    ),
  );
}
