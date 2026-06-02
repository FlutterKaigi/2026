import 'package:data/data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'environment.dart';

part 'firebase_data_client.g.dart';

@Riverpod(keepAlive: true)
FirebaseDataClient firebaseDataClient(Ref ref) {
  final environment = ref.watch(environmentProvider);
  return FirebaseDataClient.emulator(
    projectId: environment.firebaseProjectId,
    host: environment.firestoreHost,
  );
}
