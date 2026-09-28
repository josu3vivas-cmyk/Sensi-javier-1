import SwiftUI
import WebKit
import UIKit

@main
struct SensiJavierApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "deviceInfo")
        config.userContentController = controller
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }
    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler {
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "deviceInfo", let webView = message.webView else { return }
            let info = DeviceInfo.current
            let json = """
            {"ios":"\(info.ios)","model":"\(info.model)","identifier":"\(info.identifier)"}
            """
            let script = "window.__nativeDeviceInfo = \(json); if (window.applyNativeDeviceInfo) window.applyNativeDeviceInfo(window.__nativeDeviceInfo);"
            webView.evaluateJavaScript(script)
        }
    }
}

struct DeviceInfo {
    let ios: String
    let model: String
    let identifier: String

    static var current: DeviceInfo {
        let identifier = hardwareIdentifier()
        return DeviceInfo(ios: UIDevice.current.systemVersion,
                          model: modelName(for: identifier),
                          identifier: identifier)
    }

    private static func hardwareIdentifier() -> String {
        var size: size_t = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    private static func modelName(for id: String) -> String {
        let map: [String: String] = [
            "iPhone14,5":"iPhone 13", "iPhone14,7":"iPhone 14", "iPhone14,8":"iPhone 14 Plus",
            "iPhone15,2":"iPhone 14 Pro", "iPhone15,3":"iPhone 14 Pro Max",
            "iPhone15,4":"iPhone 15", "iPhone15,5":"iPhone 15 Plus", "iPhone16,1":"iPhone 15 Pro", "iPhone16,2":"iPhone 15 Pro Max",
            "iPhone17,3":"iPhone 16", "iPhone17,4":"iPhone 16 Plus", "iPhone17,1":"iPhone 16 Pro", "iPhone17,2":"iPhone 16 Pro Max",
            "iPhone17,5":"iPhone 16e", "iPhone18,1":"iPhone 17", "iPhone18,2":"iPhone 17 Air", "iPhone18,3":"iPhone 17 Pro", "iPhone18,4":"iPhone 17 Pro Max"
        ]
        return map[id] ?? "iPhone (\(id))"
    }
}
