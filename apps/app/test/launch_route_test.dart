import 'package:app/core/router/launch_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// iOS が `FlutterEngine.sendDeepLinkToFramework` で送るのと同じ
  /// プラットフォームメッセージを届け、フレームワークが返した結果を返す。
  Future<bool?> pushRouteInformation(String location) async {
    bool? handled;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('pushRouteInformation', {'location': location}),
      ),
      (reply) => handled = reply == null ? null : const JSONMethodCodec().decodeEnvelope(reply) as bool?,
    );
    return handled;
  }

  test('keeps the last universal link pushed while attached and reports it as handled', () async {
    final observer = LaunchRouteObserver()..attach();
    addTearDown(observer.detach);

    expect(observer.route, isNull);

    expect(await pushRouteInformation('https://2026-app.flutterkaigi.jp/'), isTrue);
    expect(observer.route, Uri.parse('https://2026-app.flutterkaigi.jp/'));

    expect(await pushRouteInformation('https://2026-app.flutterkaigi.jp/x/v1.other-uid.9999999999.deadbeef'), isTrue);
    expect(observer.route, Uri.parse('https://2026-app.flutterkaigi.jp/x/v1.other-uid.9999999999.deadbeef'));
  });

  test('stops taking links once detached so the Router receives them instead', () async {
    final observer = LaunchRouteObserver()..attach();
    expect(await pushRouteInformation('https://2026-app.flutterkaigi.jp/settings'), isTrue);

    observer.detach();

    // 他に observer がいなければフレームワークは未処理(false)を返す。
    expect(await pushRouteInformation('https://2026-app.flutterkaigi.jp/x/v1.other-uid.9999999999.deadbeef'), isFalse);
    expect(observer.route, Uri.parse('https://2026-app.flutterkaigi.jp/settings'));
  });

  test('launchRouteProvider is null unless main overrides it', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(launchRouteProvider), isNull);
  });
}
