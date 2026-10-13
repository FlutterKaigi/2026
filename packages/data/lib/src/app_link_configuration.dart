import 'app_link_origins.dart';

/// App origins belonging to one backend environment.
///
/// Newly generated links use [origin]. Scanners accept [allowedOrigins].
/// Individual features can add their own compatibility origins separately.
final class AppLinkConfiguration {
  const AppLinkConfiguration.production() : origin = productionAppOrigin, allowedOrigins = const {productionAppOrigin};

  const AppLinkConfiguration.staging() : origin = stagingAppOrigin, allowedOrigins = const {stagingAppOrigin};

  const AppLinkConfiguration.develop() : origin = null, allowedOrigins = const {};

  /// Null for local emulators, whose QR payloads must not open deployed apps.
  final String? origin;

  /// Immutable app origins whose links belong to this backend.
  final Set<String> allowedOrigins;
}
