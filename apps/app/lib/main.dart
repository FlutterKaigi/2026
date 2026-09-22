import 'package:app/core/firebase/app_check_initializer.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/provider/app_locale.dart';
import 'package:app/core/provider/environment.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:app/core/remote_config/remote_config_repository.dart';
import 'package:app/core/router/app_url_strategy.dart';
import 'package:app/core/router/launch_route.dart';
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

  // 以下の初期化を待つ間に届く Universal Link を取りこぼさないための準備。
  // iOS はリンクを Flutter の最初のフレーム描画後にしか渡さず、3 秒以内に
  // 描画されなければリンクを捨てて Safari に投げ返すため、iOS では先に
  // 1 フレーム(起動画面と同じ白)を描画しておく(`LaunchRouteObserver` 参照)。
  final launchRoute = LaunchRouteObserver()..attach();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    runApp(const ColoredBox(color: Color(0xFFFFFFFF)));
  }

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
          launchRouteProvider.overrideWithValue(launchRoute.route),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          talkerProvider.overrideWithValue(talker),
          remoteConfigRepositoryProvider.overrideWithValue(remoteConfigRepository),
        ],
        child: const App(),
      ),
    ),
  );
  // 以降のリンクは本体ツリーの Router が受け取る。
  launchRoute.detach();
}
