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
