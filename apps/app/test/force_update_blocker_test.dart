import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/i18n/strings_en.g.dart';
import 'package:app/core/provider/package_info.dart';
import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/feature/force_update/data/force_update_provider.dart';
import 'package:app/feature/force_update/ui/force_update_blocker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fake_remote_config_repository.dart';

const _requiredPolicy =
    '{"minimum_version":{"ios":"2.0.0","android":"2.0.0"},'
    '"store_urls":{"ios":"","android":"https://play.google.com/store"},'
    '"message":{"ja":"リモートの更新メッセージ","en":"Remote update message"}}';

/// 小さな画面と大きな文字サイズではダイアログに収まりきらない長さの本文。
const _longMessage =
    'アップデートのお願いです。'
    '会期中の機能を利用するには最新バージョンのアプリが必要です。'
    'ストアから最新バージョンを入手したうえで、もう一度アプリを開いてください。'
    'うまく更新できない場合は会場のインフォメーションデスクまでお声がけください。';

const _longMessagePolicy =
    '{"minimum_version":{"ios":"2.0.0","android":"2.0.0"},'
    '"store_urls":{"ios":"","android":"https://play.google.com/store"},'
    '"message":{"ja":"$_longMessage"}}';

const _requiredPolicyWithoutMessage =
    '{"minimum_version":{"ios":"2.0.0","android":"2.0.0"},'
    '"store_urls":{"ios":"","android":"https://play.google.com/store"}}';

void main() {
  late FakeRemoteConfigRepository repository;

  setUp(() => repository = FakeRemoteConfigRepository());
  tearDown(() => repository.dispose());

  Future<void> pumpBlocker(
    WidgetTester tester, {
    String? policy,
    AppLocale locale = AppLocale.ja,
    TargetPlatform platform = TargetPlatform.android,
    ExternalUrlLauncher? launcher,
    Widget background = const Scaffold(body: Center(child: Text('下の画面'))),
  }) async {
    if (policy != null) {
      repository.values[RemoteConfigKeys.forceUpdate] = policy;
    }
    if (locale == AppLocale.en) {
      // 本番では英語の文言が deferred で読み込まれるが、テスト VM では
      // その読み込みを完了できないため直接登録する。
      LocaleSettings.instance.translationMap[locale] ??= TranslationsEn();
    }
    LocaleSettings.setLocaleSync(locale);
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.ja));

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            remoteConfigRepositoryProvider.overrideWithValue(repository),
            forceUpdateTargetProvider.overrideWithValue((isWeb: false, platform: platform)),
            packageInfoProvider.overrideWithValue(
              AsyncData(
                PackageInfo(
                  appName: 'FlutterKaigi 2026',
                  packageName: 'jp.flutterkaigi.conf2026',
                  version: '1.0.0',
                  buildNumber: '1',
                ),
              ),
            ),
          ],
          child: MaterialApp(
            locale: locale.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: ForceUpdateBlocker(launcher: launcher, child: background),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// MaterialApp のルート自身もバリアを持つため、重ねた分だけを数える。
  final barrier = find.descendant(
    of: find.byType(ForceUpdateBlocker),
    matching: find.byType(ModalBarrier),
  );

  testWidgets('stays out of the way while no update is required', (tester) async {
    await pumpBlocker(tester);

    expect(find.text('下の画面'), findsOneWidget);
    expect(find.text('アップデートが必要です'), findsNothing);
    expect(barrier, findsNothing);
  });

  testWidgets('blocks the screen with an undismissable prompt', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpBlocker(tester, policy: _requiredPolicy);

    expect(find.text('アップデートが必要です'), findsOneWidget);
    expect(find.text('アップデート'), findsOneWidget);
    // 下の画面は残るが、バリアで操作も読み上げもできない。
    expect(find.text('下の画面'), findsOneWidget);
    expect(barrier, findsOneWidget);
    expect(find.bySemanticsLabel('下の画面'), findsNothing);

    // バリアをタップしても閉じない。
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('アップデートが必要です'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('prefers the remote message of the current locale', (tester) async {
    await pumpBlocker(tester, policy: _requiredPolicy);
    expect(find.text('リモートの更新メッセージ'), findsOneWidget);

    await pumpBlocker(tester, policy: _requiredPolicy, locale: AppLocale.en);

    expect(find.text('Update Required'), findsOneWidget);
    expect(find.text('Remote update message'), findsOneWidget);
  });

  testWidgets('falls back to the bundled message without a remote one', (tester) async {
    await pumpBlocker(tester, policy: _requiredPolicyWithoutMessage);

    expect(
      find.text('新しいバージョンのアプリが利用可能です。最新バージョンにアップデートしてください。'),
      findsOneWidget,
    );
  });

  testWidgets('opens the store URL of the running platform', (tester) async {
    final opened = <Uri>[];
    await pumpBlocker(
      tester,
      policy: _requiredPolicy,
      launcher: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    await tester.tap(find.text('アップデート'));
    await tester.pumpAndSettle();

    expect(opened.single, Uri.parse('https://play.google.com/store'));
    // ストアを開いてもプロンプトは残る。
    expect(find.text('アップデートが必要です'), findsOneWidget);
  });

  testWidgets('blocks every route from MaterialApp.builder', (tester) async {
    // app.dart と同じ差し込み位置。Navigator の外側でも組み立てられること、
    // そのうえで画面遷移しても残ることを確かめる。
    repository.values[RemoteConfigKeys.forceUpdate] = _requiredPolicy;
    LocaleSettings.setLocaleSync(AppLocale.ja);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('最初の画面')),
        ),
        GoRoute(
          path: '/next',
          builder: (_, _) => const Scaffold(body: Text('次の画面')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            remoteConfigRepositoryProvider.overrideWithValue(repository),
            forceUpdateTargetProvider.overrideWithValue((isWeb: false, platform: TargetPlatform.android)),
            packageInfoProvider.overrideWithValue(
              AsyncData(
                PackageInfo(
                  appName: 'FlutterKaigi 2026',
                  packageName: 'jp.flutterkaigi.conf2026',
                  version: '1.0.0',
                  buildNumber: '1',
                ),
              ),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: AppLocale.ja.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => ForceUpdateBlocker(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('アップデートが必要です'), findsOneWidget);

    router.go('/next');
    await tester.pumpAndSettle();

    expect(find.text('次の画面'), findsOneWidget);
    expect(find.text('アップデートが必要です'), findsOneWidget);
  });

  testWidgets('leaves keyboard focus alone while no update is required', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await pumpBlocker(
      tester,
      background: Scaffold(body: TextField(focusNode: focusNode, autofocus: true)),
    );

    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('keeps keyboard focus out of the blocked screen', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await pumpBlocker(
      tester,
      policy: _requiredPolicy,
      background: Scaffold(body: TextField(focusNode: focusNode, autofocus: true)),
    );

    expect(focusNode.hasFocus, isFalse);

    // 外部キーボードや支援技術から背面を掴みにいっても通らない。
    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('scrolls a long message on a small screen with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpBlocker(tester, policy: _longMessagePolicy);

    expect(tester.takeException(), isNull);
    expect(find.text(_longMessage), findsOneWidget);
    expect(find.text('アップデート'), findsOneWidget);

    // ダイアログに収まりきらない本文は、切り捨てずにスクロールで読める。
    final scrollView = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(SingleChildScrollView),
    );
    final before = tester.getRect(find.text(_longMessage)).top;
    await tester.drag(scrollView, const Offset(0, -120));
    await tester.pump();

    expect(tester.getRect(find.text(_longMessage)).top, lessThan(before));
  });

  testWidgets('opens nothing when the store URL is unconfigured', (tester) async {
    final opened = <Uri>[];
    await pumpBlocker(
      tester,
      policy: _requiredPolicy,
      platform: TargetPlatform.iOS,
      launcher: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    await tester.tap(find.text('アップデート'));
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
    expect(find.text('アップデートが必要です'), findsOneWidget);
  });
}
