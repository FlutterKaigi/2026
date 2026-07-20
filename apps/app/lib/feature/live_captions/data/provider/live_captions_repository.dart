import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides the [LiveCaptionsRepository] implementation backed by Firestore.
final liveCaptionsRepositoryProvider = Provider<LiveCaptionsRepository>(
  (ref) => FirestoreLiveCaptionsRepository(),
);
