import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/environment.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/ui/app.dart';
import 'package:data/data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // バンドルした Noto Sans JP の OFL ライセンスをアプリのライセンス一覧に登録。
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Noto Sans JP'],
      await rootBundle.loadString('res/assets/fonts/NotoSansJP/OFL.txt'),
    );
  });

  final environment = Environment.fromEnvironment();
  await LocaleSettings.useDeviceLocale();

  // dev (emulator): options stays null so FirebaseInitializer wires the local
  // emulator suite. For stg/prod, generate firebase_options.dart via
  // `flutterfire configure` and pass `DefaultFirebaseOptions.currentPlatform`.
  final hostParts = environment.firestoreHost.split(':');
  await FirebaseInitializer.ensureInitialized(
    projectId: environment.firebaseProjectId,
    host: hostParts.first,
    firestorePort: hostParts.length > 1 ? int.parse(hostParts[1]) : 8080,
  );

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          environmentProvider.overrideWithValue(environment),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const App(),
      ),
    ),
  );
}
