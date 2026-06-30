import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Application-wide [Talker] used for logging and the in-app log viewer.
///
/// Inject it into features with `ref.read(talkerProvider)` instead of creating
/// new [Talker] instances so that all logs share a single history.
final talkerProvider = Provider<Talker>((ref) => TalkerFlutter.init());
