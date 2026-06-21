import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';

import '../models/caption_segment.dart';
import 'caption_sink.dart';

/// [CaptionSink] backed by Firestore via `dart_firebase_admin`.
///
/// One instance per ingest connection: [connectionStartMs] seeds the segment
/// document id (`{epochMs}-{seq6}`) so ids sort chronologically and never
/// collide across reconnections. See §5.3.
class FirestoreSink implements CaptionSink {
  FirestoreSink(this._firestore, {required this.connectionStartMs});

  final Firestore _firestore;
  final int connectionStartMs;

  @override
  Future<void> writeInterim(String roomId, InterimCaption interim) async {
    // Overwrite the room doc with the latest interim (kill switch stays on).
    await _firestore.doc('live_captions/$roomId').set({
      'enabled': true,
      'interim': {
        'text': interim.text,
        'srcLang': interim.srcLang,
        'updatedAt': DateTime.now().toUtc(),
      },
      'updatedAt': DateTime.now().toUtc(),
    });
  }

  @override
  Future<void> appendSegment(String roomId, CaptionSegment s) async {
    final segmentId = '$connectionStartMs-${s.seq.toString().padLeft(6, '0')}';
    await _firestore.collection('live_captions/$roomId/segments').doc(segmentId).set({
      'seq': s.seq,
      'srcLang': s.srcLang,
      'srcText': s.srcText,
      'ja': s.ja,
      'en': s.en,
      'startMs': s.startMs,
      'endMs': s.endMs,
      'createdAt': DateTime.now().toUtc(),
    });
  }
}

/// Builds a [Firestore] client. When [emulatorHost] is set the client targets
/// the Firestore emulator (which accepts `Authorization: Bearer owner`), so no
/// real GCP credentials are needed for local development.
Firestore createFirestore({required String projectId, String? emulatorHost}) {
  final app = FirebaseAdminApp.initializeApp(
    projectId,
    Credential.fromApplicationDefaultCredentials(),
  );
  if (emulatorHost != null && emulatorHost.isNotEmpty) {
    app.useEmulator();
  }
  return Firestore(app);
}
