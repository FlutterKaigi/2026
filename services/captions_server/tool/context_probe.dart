import 'dart:io';

import 'package:captions_server/captions_server.dart';

/// Prints the session context the loader would inject for a room. Debug tool:
/// `dart run -DCAPTIONS_CONFIG=environments/env.dev tool/context_probe.dart [roomId]`
Future<void> main(List<String> args) async {
  final config = Config.load();
  final roomId = args.isNotEmpty ? args.first : 'hall-a';
  final firestore = createFirestore(
    projectId: config.googleCloudProject,
    emulatorHost: config.firestoreEmulatorHost,
  );
  final context = await FirestoreSessionContextLoader(firestore).load(roomId);
  stdout.writeln(context ?? '(no context)');
  exit(0);
}
