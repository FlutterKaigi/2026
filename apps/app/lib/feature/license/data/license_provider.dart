import 'package:app/feature/license/data/license_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final licenseRepositoryProvider = Provider<LicenseRepository>(
  (ref) => const LicenseRepository(),
);

final licensesProvider = FutureProvider.autoDispose<LicenseGroups>(
  (ref) => ref.watch(licenseRepositoryProvider).fetchAll(),
);
