import 'package:app/core/provider/environment.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// App links always target the backend selected at startup, including previews
/// that use the fixed staging app domain.
final appLinkConfigurationProvider = Provider<AppLinkConfiguration>((ref) {
  final flavor = ref.watch(environmentProvider.select((environment) => environment.flavor));
  return switch (flavor) {
    Flavor.production => const AppLinkConfiguration.production(),
    Flavor.staging => const AppLinkConfiguration.staging(),
    Flavor.develop => const AppLinkConfiguration.develop(),
  };
});
