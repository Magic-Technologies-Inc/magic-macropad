import AppKit
import SwiftUI
import MagicKeysCore

@main
struct MagicKeysApp: App {
    @StateObject private var model = AppModel()

    init() {
        MagicFont.registerBundledFonts()
        #if DEBUG
        Snapshot.runIfRequested()
        #endif
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel()
                .environmentObject(model)
        } label: {
            // Always rendered in the status bar, so this is where we boot the
            // HID stack — the popover content only exists while it's open.
            Image(nsImage: MenuBarIcon.image(connected: model.isConnected))
                .task { model.start() }
        }
        .menuBarExtraStyle(.window)
    }
}
