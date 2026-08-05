import Flutter
import UIKit
import AuthenticationServices

private final class AppleSignInButtonFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    AppleSignInButtonView(frame: frame, messenger: messenger)
  }
}

private final class AppleSignInButtonView: NSObject, FlutterPlatformView {
  private let button: ASAuthorizationAppleIDButton
  private let channel: FlutterMethodChannel

  init(frame: CGRect, messenger: FlutterBinaryMessenger) {
    button = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .black)
    channel = FlutterMethodChannel(name: "vnsport/apple-sign-in-button", binaryMessenger: messenger)
    super.init()
    button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
    button.cornerRadius = 12
    button.frame = frame
    button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }

  func view() -> UIView { button }

  @objc private func didTap() {
    channel.invokeMethod("appleSignInButtonPressed", arguments: nil)
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "AppleSignInButton") {
      registrar.register(AppleSignInButtonFactory(messenger: registrar.messenger()), withId: "vnsport/apple-sign-in-button")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
