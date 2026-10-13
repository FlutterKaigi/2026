import 'package:app/feature/exchange/data/provider/pending_exchange_token_provider.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final stampRallyRepositoryProvider = Provider<StampRallyRepository>((ref) => FirebaseStampRallyRepository());

final stampRallySettingsProvider = StreamProvider.autoDispose<StampRallySettings>(
  (ref) => ref.watch(stampRallyRepositoryProvider).watchSettings(),
  retry: (_, _) => null,
);

final stampRallySponsorIdsProvider = StreamProvider.autoDispose<Set<String>>(
  (ref) => ref.watch(stampRallyRepositoryProvider).watchSponsorIds(),
  retry: (_, _) => null,
);

/// Keyed by account so a previous attendee's stamps never show after an
/// account switch. The server writes the card, so it settles the outcome of a
/// scan whose response was lost to a network error.
final stampRallyCardProvider = StreamProvider.autoDispose.family<StampRallyCard, String>(
  (ref, uid) => ref.watch(stampRallyRepositoryProvider).watchCard(uid),
  retry: (_, _) => null,
);

/// A `/s/<token>` link opened before sign-in, resolved by `AccountPage` when
/// the visitor signs in elsewhere. Shares the profile-exchange pending
/// semantics, including the recorded uid.
final pendingStampRallyTokenProvider = NotifierProvider<PendingExchangeTokenNotifier, PendingExchangeToken?>(
  PendingExchangeTokenNotifier.new,
);

final _tokenPattern = RegExp(r'^[0-9a-f]{64}$');

bool isStampRallyToken(String token) => _tokenPattern.hasMatch(token);

/// Extracts the token from a `<any origin>/s/<token>` QR code. The origin is
/// not checked: the server identifies the code by its signature alone.
String? parseStampRallyUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null ||
      !const {'https', 'http'}.contains(uri.scheme) ||
      uri.pathSegments.length != 2 ||
      uri.pathSegments.first != 's' ||
      !isStampRallyToken(uri.pathSegments.last)) {
    return null;
  }
  return uri.pathSegments.last;
}
