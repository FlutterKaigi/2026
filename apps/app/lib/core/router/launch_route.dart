import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 起動処理中(`runApp` で本体のツリーを立ち上げる前)に届いた
/// `pushRouteInformation` を保持する。
///
/// iOS は Universal Link でのコールドスタート時、Flutter の最初のフレームが
/// 描画されてからリンクを Dart 側へ渡す(最初のフレームを最大 3 秒待ち、
/// 間に合わないとリンクを捨てて Safari に投げ返す — `FlutterEngine
/// sendDeepLinkToFramework`)。`main` は Firebase / App Check / Remote Config
/// の初期化を待ってから `runApp` するため、その間に届いたリンクを受け取る
/// `Router` はまだ存在しない。先に 1 フレーム描画しておき、その間のリンクを
/// ここで受け取って GoRouter の初期ロケーションに渡す。
///
/// `WidgetsBinding` は最初に `true` を返した observer でディスパッチを止める
/// ので、本体のツリーを `runApp` したら必ず [detach] して、以降のリンクが
/// `Router` に届くようにする。
class LaunchRouteObserver with WidgetsBindingObserver {
  Uri? _route;

  /// 起動処理中に届いた最後のリンク。何も届いていなければ `null`。
  Uri? get route => _route;

  void attach() => WidgetsBinding.instance.addObserver(this);

  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    _route = routeInformation.uri;
    return true;
  }
}

/// 起動処理中に [LaunchRouteObserver] が受け取ったリンク。`main` が
/// `ProviderScope` の override で渡し、`routerProvider` が初期ロケーションに
/// 使う。通常起動では `null`。
final launchRouteProvider = Provider<Uri?>((_) => null);
