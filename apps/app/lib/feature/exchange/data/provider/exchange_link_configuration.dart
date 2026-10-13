import 'package:app/core/provider/app_link_configuration.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Profile exchange additionally accepts old links hosted on the official
/// website. Other features use the shared app-only origin configuration.
typedef ExchangeLinkConfiguration = ({String? origin, Set<String> allowedOrigins});

final exchangeLinkConfigurationProvider = Provider<ExchangeLinkConfiguration>((ref) {
  final configuration = ref.watch(appLinkConfigurationProvider);
  return (
    origin: configuration.origin,
    allowedOrigins: Set<String>.unmodifiable({
      ...configuration.allowedOrigins,
      if (configuration.origin == productionAppOrigin) legacyExchangeOrigin,
    }),
  );
});
