import 'package:app/core/router/legacy_hash_route.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:web/web.dart' as web;

/// Runs before Flutter reads the initial route, without reloading the app.
void configureAppUrlStrategy() {
  final migrated = migrateLegacyHashRoute(Uri.parse(web.window.location.href));
  if (migrated != null) {
    web.window.history.replaceState(web.window.history.state, '', migrated.toString());
  }
  usePathUrlStrategy();
}
