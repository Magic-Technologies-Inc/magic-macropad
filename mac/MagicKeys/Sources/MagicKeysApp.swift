import AppKit
import SwiftUI
import MagicKeysCore
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    // Re-open the window when the user clicks the Dock icon with no windows open.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { NSApp.windows.first?.makeKeyAndOrderFront(nil) }
        return true
    }
}

@main
struct MagicKeysApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()
    @Environment(\.openWindow) private var openWindow

    init() {
        MagicFont.registerBundledFonts()
        #if DEBUG
        Snapshot.runIfRequested()
        #endif
    }

    var body: some Scene {
        // Main window — a Logi Options+-style single window, open at launch.
        WindowGroup(id: "main") {
            ConfigView()
                .environmentObject(model)
                .task { model.start() }
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)

        // Menu-bar presence for quick status while the window is closed.
        MenuBarExtra {
            Text(model.isConnected
                 ? "K1 connected" + (model.deviceInfo.map { " — fw \($0.firmwareMajor).\($0.firmwareMinor)" } ?? "")
                 : "K1 not connected")
            Divider()
            Button("Open Magic Keys…") {
                NSApp.setActivationPolicy(.regular)
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            Toggle("Launch at Login", isOn: Binding(
                get: { SMAppService.mainApp.status == .enabled },
                set: { enable in
                    do {
                        if enable { try SMAppService.mainApp.register() }
                        else { try SMAppService.mainApp.unregister() }
                    } catch {
                        NSLog("MagicKeys: launch-at-login failed: \(error)")
                    }
                }))
            #if DEBUG
            Divider()
            Menu("Virtual K1") {
                ForEach(0..<3, id: \.self) { key in
                    Button("Key \(key + 1): tap") { model.simulatePress(key: key) }
                    Button("Key \(key + 1): double tap") {
                        model.simulatePress(key: key)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            model.simulatePress(key: key)
                        }
                    }
                    Button("Key \(key + 1): hold") { model.simulatePress(key: key, duration: 0.6) }
                }
            }
            #endif
            Divider()
            Button("Quit Magic Keys") { NSApp.terminate(nil) }
        } label: {
            Image(systemName: model.isConnected ? "circle.grid.3x1.fill" : "circle.grid.3x1")
        }
    }
}
