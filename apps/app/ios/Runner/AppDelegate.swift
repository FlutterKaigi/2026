import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // UIScene ではプラグインの登録がこのメソッドの後になるが、通知センターの delegate は起動完了前に設定する必要がある。
    FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate()
    Self.reportMessagingSceneConnectionAsUnhandled()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ReservedRegions") {
      Self.registerReservedRegions(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VerticalBarEdge") {
      Self.registerVerticalBarEdge(with: registrar)
    }
  }

  // Flutter は safe area の形から iPhone Duo の縦帯を推測している。想定していない状態（iPad のウインドウ表示など）で
  // 誤判定しないよう、UIKit が縦帯を置く辺を返し、変わったら知らせる。
  private static func registerVerticalBarEdge(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "jp.flutterkaigi.conf2026/vertical_bar_edge",
      binaryMessenger: registrar.messenger()
    )
    var observing = false
    channel.setMethodCallHandler { [weak registrar] call, result in
      guard call.method == "edge" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard #available(iOS 27.1, *), let viewController = registrar?.viewController else {
        result(nil)
        return
      }
      if !observing {
        observing = true
        _ = viewController.registerForTraitChanges(UITraitCollection.systemTraitsAffectingVerticalBarEdge) {
          (viewController: UIViewController, _: UITraitCollection) in
          channel.invokeMethod("edgeChanged", arguments: AppDelegate.name(of: viewController.traitCollection.verticalBarEdge))
        }
      }
      result(AppDelegate.name(of: viewController.traitCollection.verticalBarEdge))
    }
  }

  @available(iOS 27.1, *)
  private static func name(of edge: UIVerticalBarEdge) -> String {
    switch edge {
    case .leading:
      return "leading"
    case .trailing:
      return "trailing"
    default:
      return "unspecified"
    }
  }

  // iPhone Duo の縦帯にはカメラ穴が入り、端末の向きによって上端にも下端にも来る。Flutter はこの位置を
  // 受け取れないので、縦帯にタブを並べる画面のために UIKit の値を返す。
  private static func registerReservedRegions(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "jp.flutterkaigi.conf2026/reserved_regions",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak registrar] call, result in
      guard call.method == "occlusions" else {
        result(FlutterMethodNotImplemented)
        return
      }
      // 取れないときは nil を返し、「カメラ穴がない」と区別して Flutter 側の既定の余白を使わせる。
      guard #available(iOS 27.1, *), let view = registrar?.viewController?.view else {
        result(nil)
        return
      }
      result(
        view.reservedRegions(kind: .occlusion).map { region in
          [
            "x": region.frame.minX, "y": region.frame.minY,
            "width": region.frame.width, "height": region.frame.height,
            "active": region.isActive,
          ]
        }
      )
    }
  }

  // firebase_messaging 16.7.0 は scene:willConnectToSession:options: を void で実装しているが、Flutter は
  // 「プラグインが接続を処理したか」の BOOL として読む。不定値が YES になると、コールドスタート時の
  // Universal Link が Flutter に渡らない(firebase/flutterfire#18731)。修正(#18733)と同じく常に NO を
  // 返すようにする。この修正を含む firebase_messaging に上げたら削除する。
  private static func reportMessagingSceneConnectionAsUnhandled() {
    let selector = NSSelectorFromString("scene:willConnectToSession:options:")
    guard let method = class_getInstanceMethod(FLTFirebaseMessagingPlugin.self, selector) else {
      return
    }
    typealias Original = @convention(c) (AnyObject, Selector, UIScene, UISceneSession, UIScene.ConnectionOptions?) -> Void
    let original = unsafeBitCast(method_getImplementation(method), to: Original.self)
    let replacement: @convention(block) (AnyObject, UIScene, UISceneSession, UIScene.ConnectionOptions?) -> Bool = {
      plugin, scene, session, options in
      original(plugin, selector, scene, session, options)
      return false
    }
    method_setImplementation(method, imp_implementationWithBlock(replacement))
  }
}
