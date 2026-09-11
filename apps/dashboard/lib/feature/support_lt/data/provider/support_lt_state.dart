import 'package:dashboard/feature/auth/data/provider/auth_state.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final supportLtRepositoryProvider = Provider<SupportLtRepository>(
  (_) => FirebaseSupportLtRepository(),
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
