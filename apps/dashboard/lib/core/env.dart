import 'package:data/firebase_options.dart';

import '../firebase_options_prod.dart' as prod;
import '../firebase_options_stg.dart' as stg;

enum Flavor {
  dev,
  stg,
  prod;

  static Flavor get current {
    const flavor = String.fromEnvironment('FLAVOR');
    return Flavor.values.byName(flavor);
  }
}

class Env {
  static FirebaseOptions? get firebaseOptions => switch (Flavor.current) {
    Flavor.dev => null, // dev: FirebaseInitializer が _localOptions() を使いエミュレータに接続
    Flavor.stg => stg.DefaultFirebaseOptions.currentPlatform,
    Flavor.prod => prod.DefaultFirebaseOptions.currentPlatform,
  };
}
