import 'package:dashboard/core/firebase/stg/firebase_options_stg.dart' as stg;
import 'package:dashboard/core/firebase/stg/firebase_options_stg.dart' as prod;
import 'package:data/firebase_options.dart';

enum Flavor {
  dev,
  stg,
  prod
  ;

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
