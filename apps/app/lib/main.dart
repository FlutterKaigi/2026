import 'package:app/core/firebase/app_check_initializer.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/provider/app_locale.dart';
import 'package:app/core/provider/environment.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:app/core/remote_config/remote_config_repository.dart';
import 'package:app/core/router/app_url_strategy.dart';
import 'package:app/core/ui/app.dart';
import 'package:data/data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

Future<void> main() async {
  configureAppUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // バンドルした Noto Sans JP の OFL ライセンスをアプリのライセンス一覧に登録。
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Noto Sans JP'],
      await rootBundle.loadString('res/assets/fonts/NotoSansJP/OFL.txt'),
    );
  });

  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Three.js / OrbitControls'],
      await rootBundle.loadString('assets/venue_map/THREE_LICENSE.txt'),
    );
  });

  final environment = Environment.fromEnvironment();
  final sharedPreferences = await SharedPreferences.getInstance();
  await initializeAppLocale(sharedPreferences);

  // dev uses the local Emulator Suite. CI generates stg/prod SDK settings with
  // FlutterFire CLI into the ignored lib/firebase_options.dart before building.
  final hostParts = environment.firestoreHost.split(':');
  await FirebaseInitializer.ensureInitialized(
    options: environment.firebaseOptions,
    useEmulators: environment.flavor == Flavor.develop,
    projectId: environment.firebaseProjectId,
    host: hostParts.first,
    firestorePort: hostParts.length > 1 ? int.parse(hostParts[1]) : 8080,
  );
  await ensureAppCheckInitialized(environment);

  // Share one Talker with the app so startup logs land in the in-app viewer.
  final talker = TalkerFlutter.init();
  final remoteConfigRepository = FirebaseRemoteConfigRepository(flavor: environment.flavor, talker: talker);
  // Fails open and blocks startup for a few seconds at most: it logs and
  // returns instead of throwing, and a fetch that is still in flight keeps
  // running in the background, so a slow or broken Remote Config cannot hold
  // up the first frame.
  await remoteConfigRepository.initialize();

  runApp(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          environmentProvider.overrideWithValue(environment),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          talkerProvider.overrideWithValue(talker),
          remoteConfigRepositoryProvider.overrideWithValue(remoteConfigRepository),
        ],
        child: const App(),
      ),
    ),
  );
}
