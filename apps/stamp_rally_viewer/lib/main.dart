import 'package:data/data.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app.dart';
import 'environment.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

Future<void> _initialize() async {
  final environment = Environment.fromEnvironment();
  await FirebaseInitializer.ensureInitialized(
    options: environment.firebaseOptions,
    useEmulators: environment.usesEmulators,
    projectId: environment.firebaseProjectId,
    host: environment.emulatorHost,
  );
  if (!environment.usesEmulators) {
    await FirebaseAppCheck.instance.activate(
      providerWeb: kDebugMode ? WebDebugProvider() : ReCaptchaEnterpriseProvider(environment.appCheckSiteKey),
    );
  }
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<void> _startup = _initialize();

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _startup,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
        return const ProviderScope(child: StampRallyViewerApp());
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FlutterKaigi 2026 スタンプラリー状況確認',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF1565C0)),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: snapshot.connectionState == ConnectionState.done && snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 40),
                        const SizedBox(height: 16),
                        const Text('アプリを起動できませんでした。', textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        const Text('接続を確認し、もう一度お試しください。', textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => setState(() => _startup = _initialize()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('再試行'),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('読み込み中…'),
                      ],
                    ),
            ),
          ),
        ),
      );
    },
  );
}
