#if DEBUG
import AppKit
import SwiftUI
import MagicKeysCore

/// Renders the panel to a PNG headlessly (independent of windows/Spaces) so the
/// design can be reviewed without a live display. Triggered by MAGICKEYS_SNAPSHOT=<path>.
@MainActor
enum Snapshot {
    static func runIfRequested() {
        guard let path = ProcessInfo.processInfo.environment["MAGICKEYS_SNAPSHOT"] else { return }

        let model = AppModel()
        model.configStore.update {
            $0.profiles[0].keys[0].tap = .openURL(urlString: "https://usemagic.io")
            $0.profiles[0].keys[0].hold = .media(command: .playPause)
            $0.addProfile(bundleID: "com.apple.Terminal", name: "Terminal", symbol: "terminal")
        }

        func render(_ colorScheme: ColorScheme, to url: URL) {
            let view = MenuBarPanel()
                .environmentObject(model)
                .environment(\.colorScheme, colorScheme)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            guard let image = renderer.nsImage,
                  let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else { return }
            try? png.write(to: url)
        }

        let base = (path as NSString).deletingPathExtension
        render(.light, to: URL(fileURLWithPath: base + "-light.png"))
        render(.dark, to: URL(fileURLWithPath: base + "-dark.png"))
        exit(0)
    }
}
#endif
