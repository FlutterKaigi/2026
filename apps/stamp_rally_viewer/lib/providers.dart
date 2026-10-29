import 'package:data/data.dart';
import 'package:data/user.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => FirebaseAuthRepository());

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
  retry: (_, _) => null,
);

final stampRallyRepositoryProvider = Provider<StampRallyRepository>((ref) => FirebaseStampRallyRepository());

final sponsorRepositoryProvider = Provider<SponsorRepository>((ref) => FirestoreSponsorRepository());

final settingsProvider = StreamProvider.autoDispose<StampRallySettings>(
  (ref) => ref.watch(stampRallyRepositoryProvider).watchSettings(),
  retry: (_, _) => null,
);

final sponsorIdsProvider = StreamProvider.autoDispose<Set<String>>(
  (ref) => ref.watch(stampRallyRepositoryProvider).watchSponsorIds(),
  retry: (_, _) => null,
);

final sponsorsProvider = StreamProvider.autoDispose<List<Sponsor>>(
  (ref) => ref.watch(sponsorRepositoryProvider).watchAll(excludeUnsupportedTiers: true),
  retry: (_, _) => null,
);

// Key each subscription by account so switching users cannot reuse another
// attendee's card. Only authenticated content should subscribe to this provider.
final cardProvider = StreamProvider.autoDispose.family<StampRallyCard, String>(
  (ref, uid) => ref.watch(stampRallyRepositoryProvider).watchCard(uid),
  retry: (_, _) => null,
);
