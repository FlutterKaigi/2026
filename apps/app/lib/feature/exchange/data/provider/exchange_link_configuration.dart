import 'package:app/core/provider/environment.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Generation and scanning share the same backend-specific origins. PR web
/// previews using staging also issue the fixed staging link, so installed
/// staging apps can handle it without associating every preview hostname.
typedef ExchangeLinkConfiguration = ({String? origin, Set<String> allowedOrigins});

final exchangeLinkConfigurationProvider = Provider<ExchangeLinkConfiguration>((ref) {
  final flavor = ref.watch(environmentProvider.select((environment) => environment.flavor));
  return switch (flavor) {
    Flavor.production => (
      origin: productionExchangeOrigin,
      allowedOrigins: const {productionExchangeOrigin, legacyExchangeOrigin},
    ),
    Flavor.staging => (origin: stagingExchangeOrigin, allowedOrigins: const {stagingExchangeOrigin}),
    // Emulator tokens must never lead to a real production or staging backend.
    Flavor.develop => (origin: null, allowedOrigins: const <String>{}),
  };
});
