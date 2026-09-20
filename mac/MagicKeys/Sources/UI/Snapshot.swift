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
            // Default profile: tap + hold bound (Terminal will inherit hold).
            $0.profiles[0].keys[0].tap = .openURL(urlString: "https://usemagic.io")
            $0.profiles[0].keys[0].hold = .media(command: .playPause)
            let id = $0.addProfile(bundleID: "com.apple.Terminal", name: "Terminal", symbol: "terminal")
            if let i = $0.profileIndex(id: id) {
                $0.profiles[i].keys[0].tap = .shellScript(script: "clear", name: nil)  // Terminal-specific tap
            }
        }
        // Show the Terminal profile so the inherited "Default" tag is visible.
        if ProcessInfo.processInfo.environment["MAGICKEYS_SNAPSHOT_PROFILE"] == "app" {
            model.editingProfileID = "com.apple.Terminal"
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

        func renderPicker(to url: URL) {
            let view = ActionPickerSheet(
                title: "Assign to tap",
                current: .shellScript(script: "", name: nil),
                onSet: { _ in }, onClose: {})
                .frame(width: 442, height: 290)
                .padding(16)
                .background(MagicColor.surfaceGlass)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else { return }
            try? png.write(to: url)
        }

        func renderRecorder(to url: URL) {
            let view = VStack(alignment: .leading, spacing: 12) {
                Text("KEYSTROKE").font(MagicFont.text(11, weight: .semibold)).foregroundStyle(MagicColor.textTertiary)
                KeyRecorderField(keyCode: .constant(0), modifiers: .constant([]))       // empty
                KeyRecorderField(keyCode: .constant(9), modifiers: .constant([.command, .shift]))  // ⌘⇧V
            }
            .frame(width: 320)
            .padding(20)
            .background(MagicColor.surfaceCard)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else { return }
            try? png.write(to: url)
        }

        let base = (path as NSString).deletingPathExtension
        render(.light, to: URL(fileURLWithPath: base + "-light.png"))
        render(.dark, to: URL(fileURLWithPath: base + "-dark.png"))
        renderPicker(to: URL(fileURLWithPath: base + "-picker.png"))
        renderRecorder(to: URL(fileURLWithPath: base + "-recorder.png"))
        exit(0)
    }
}
#endif
