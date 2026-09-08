#if DEBUG
import AppKit
import SwiftUI
import MagicKeysCore

/// Renders ConfigView to a PNG headlessly (independent of windows/Spaces) so the
/// design can be reviewed without a live display. Triggered by MAGICKEYS_SNAPSHOT=<path>.
@MainActor
enum Snapshot {
    static func runIfRequested() {
        guard let path = ProcessInfo.processInfo.environment["MAGICKEYS_SNAPSHOT"] else { return }

        let model = AppModel()
        // Seed a couple of bindings so the cards show assigned states.
        model.configStore.update {
            $0.keys[0].tap = .openURL(urlString: "https://usemagic.io")
            $0.keys[0].hold = .media(command: .playPause)
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

        // A focused render of expanded gesture cards (inline editor), which the
        // panel's ScrollView hides from ImageRenderer.
        func renderEditors(to url: URL) {
            let view = EditorsProbe()
                .frame(width: 460, height: 360)
                .background(MagicColor.surfacePage)
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
        renderEditors(to: URL(fileURLWithPath: base + "-editors.png"))
        exit(0)
    }
}

/// Three expanded gesture cards showing the inline editor for each field type,
/// used only by the Snapshot harness.
private struct EditorsProbe: View {
    @State private var url: ActionConfig? = .openURL(urlString: "https://usemagic.io")
    @State private var keystroke: ActionConfig? = .keystroke(keyCode: 15, modifiers: [.command, .shift])
    @State private var media: ActionConfig? = .media(command: .playPause)

    var body: some View {
        VStack(spacing: 12) {
            GestureCard(title: "Tap", gestureIcon: "hand.tap",
                        action: $url, isExpanded: .constant(true))
            GestureCard(title: "Double Tap", gestureIcon: "hand.tap.fill",
                        action: $keystroke, isExpanded: .constant(true))
            GestureCard(title: "Hold", gestureIcon: "hand.raised",
                        action: $media, isExpanded: .constant(true))
        }
        .padding(16)
    }
}
#endif
