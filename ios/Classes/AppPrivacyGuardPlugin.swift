import Flutter
import UIKit

// MARK: - Watermark overlay (separate UIWindow)
final class WatermarkOverlay {
    static let shared = WatermarkOverlay()
    private var window: UIWindow?
    private let imageView = UIImageView()

    func show(image: UIImage,
              size: CGFloat = 22,
              offsetY: CGFloat = 6,
              alpha: CGFloat = 0.9) {

        if let w = window {
            imageView.image = image
            imageView.alpha = alpha
            updateConstraints(size: size, offsetY: offsetY)
            w.isHidden = false
            return
        }

        if #available(iOS 13.0, *) {
            guard
                let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive })
            else {
                // Fallback: frame-based
                let w = UIWindow(frame: UIScreen.main.bounds)
                buildWindow(w, image: image, size: size, offsetY: offsetY, alpha: alpha)
                return
            }
            let w = UIWindow(windowScene: scene)
            buildWindow(w, image: image, size: size, offsetY: offsetY, alpha: alpha)
        } else {
            // iOS 12 va oldin
            let w = UIWindow(frame: UIScreen.main.bounds)
            buildWindow(w, image: image, size: size, offsetY: offsetY, alpha: alpha)
        }
    }

    private func buildWindow(_ w: UIWindow,
                             image: UIImage,
                             size: CGFloat,
                             offsetY: CGFloat,
                             alpha: CGFloat) {
        w.backgroundColor = .clear
        // 🔝 Blur va boshqa app subview’laridan ham tepada turadi
        w.windowLevel = .alert + 1

        // ⚠️ Fokusni tortib olmasin:
        w.isUserInteractionEnabled = false

        let vc = UIViewController()
        vc.view.backgroundColor = .clear

        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = alpha
        imageView.isUserInteractionEnabled = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        vc.view.addSubview(imageView)
        w.rootViewController = vc

        // ❗️ makeKeyAndVisible() EMAS — shunchaki ko‘rinadigan qiling
        w.isHidden = false

        self.window = w
        updateConstraints(size: size, offsetY: offsetY)
    }

    private func updateConstraints(size: CGFloat, offsetY: CGFloat) {
        guard let v = window?.rootViewController?.view else {
            return
        }
        NSLayoutConstraint.deactivate(imageView.constraints)
        NSLayoutConstraint.activate([
                                        imageView.centerXAnchor.constraint(equalTo: v.centerXAnchor),
                                        imageView.topAnchor.constraint(equalTo: v.safeAreaLayoutGuide.topAnchor, constant: offsetY),
                                        imageView.widthAnchor.constraint(equalToConstant: size),
                                        imageView.heightAnchor.constraint(equalToConstant: size),
                                    ])
    }

    func update(size: CGFloat? = nil, offsetY: CGFloat? = nil, alpha: CGFloat? = nil) {
        if let a = alpha {
            imageView.alpha = a
        }
        if let s = size, let o = offsetY {
            updateConstraints(size: s, offsetY: o)
        }
    }

    func hide() {
        window?.isHidden = true
        window = nil
    }
}


// MARK: - Existing plugin + watermark methods
public class AppPrivacyGuardPlugin: NSObject, FlutterPlugin {
    private var blurView: UIVisualEffectView?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "app_privacy_guard", binaryMessenger: registrar.messenger())
        let instance = AppPrivacyGuardPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enableBlur":
            attachBlur()
            result(nil)
        case "disableBlur":
            removeBlur()
            result(nil)
        case "enableSecure":
            // iOS: no-op
            result(nil)
        case "disableSecure":
            result(nil)

            // --- Watermark methods ---
        case "showWatermark":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "args", message: "No args", details: nil)); return
            }
            let size = (args["size"] as? NSNumber)?.doubleValue ?? 22.0
            let offsetY = (args["offsetY"] as? NSNumber)?.doubleValue ?? 6.0
            let alpha = (args["alpha"] as? NSNumber)?.doubleValue ?? 0.9

            var image: UIImage?
            if let assetName = args["assetName"] as? String, !assetName.isEmpty {
                image = UIImage(named: assetName)
            }
            if image == nil, let base64 = args["base64"] as? String,
               let data = Data(base64Encoded: base64) {
                image = UIImage(data: data)
            }
            guard let img = image else {
                result(FlutterError(code: "image", message: "No image provided", details: nil)); return
            }

            WatermarkOverlay.shared.show(image: img,
                                         size: CGFloat(size),
                                         offsetY: CGFloat(offsetY),
                                         alpha: CGFloat(alpha))
            result(nil)

        case "hideWatermark":
            WatermarkOverlay.shared.hide()
            result(nil)

        case "updateWatermark":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "args", message: "No args", details: nil)); return
            }
            let size = (args["size"] as? NSNumber)?.doubleValue
            let offsetY = (args["offsetY"] as? NSNumber)?.doubleValue
            let alpha = (args["alpha"] as? NSNumber)?.doubleValue
            WatermarkOverlay.shared.update(size: size.flatMap(CGFloat.init),
                                           offsetY: offsetY.flatMap(CGFloat.init),
                                           alpha: alpha.flatMap(CGFloat.init))
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func keyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
            .compactMap {
                $0 as? UIWindowScene
            }
            .flatMap {
                $0.windows
            }
            .first {
                $0.isKeyWindow
            }
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    private func attachBlur() {
        guard blurView == nil, let window = keyWindow() else {
            return
        }
        let effect = UIBlurEffect(style: .regular)
        let bv = UIVisualEffectView(effect: effect)
        bv.frame = window.bounds
        bv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(bv)
        blurView = bv
    }

    private func removeBlur() {
        blurView?.removeFromSuperview()
        blurView = nil
    }
}
