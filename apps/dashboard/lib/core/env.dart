import 'package:dashboard/firebase_options_prod.dart' as prod;
import 'package:dashboard/firebase_options_stg.dart' as stg;
import 'package:data/firebase_options.dart';

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

  // reCAPTCHA v3 サイトキー（公開鍵）。dev はエミュレータのため App Check 不要。
  static String? get appCheckSiteKey => switch (Flavor.current) {
    Flavor.dev => null,
    Flavor.stg => '6LfWai0tAAAAAIUGeAnHvjG8urMNLcNzDYhjfkXh',
    Flavor.prod => '6LdAui0tAAAAAIHn1By_OC-crL4qvl8KACa8_p1n',
  };
}
