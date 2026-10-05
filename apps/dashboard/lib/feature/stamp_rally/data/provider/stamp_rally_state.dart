import 'package:dashboard/core/env.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final stampRallyRepositoryProvider = Provider<StampRallyRepository>((_) => FirebaseStampRallyRepository());

final stampRallySettingsProvider = StreamProvider<StampRallySettings>(
  (ref) => ref.watch(stampRallyRepositoryProvider).watchSettings(),
);

final stampRallySponsorIdsProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(stampRallyRepositoryProvider).watchSponsorIds(),
);

/// The app's web origin for this dashboard's Firebase project, since each
/// project signs QR tokens with its own secret.
String stampRallyOrigin(Flavor flavor) => switch (flavor) {
  Flavor.prod => 'https://2026-app.flutterkaigi.jp',
  // dev のトークンはエミュレータに接続した dev アプリでしか通らず、
  // アプリはドメインを照合しないため STG のドメインを流用する。
  Flavor.stg || Flavor.dev => 'https://stg-flutterkaigi-2026-conference-app.flutterkaigi.workers.dev',
};
