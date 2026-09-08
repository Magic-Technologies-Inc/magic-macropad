import SwiftUI
import MagicKeysCore

@main
struct MagicKeysApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            Text(model.isConnected
                 ? "K1 connected" + (model.deviceInfo.map { " — fw \($0.firmwareMajor).\($0.firmwareMinor)" } ?? "")
                 : "K1 not connected")
            Divider()
            Button("Configure…") {
                openWindow(id: "config")
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Quit Magic Keys") { NSApp.terminate(nil) }
        } label: {
            Image(systemName: model.isConnected ? "circle.grid.3x1.fill" : "circle.grid.3x1")
                .task { model.start() }
        }

        Window("Magic Keys", id: "config") {
            Text("Configuration UI lands in Task 10")
                .frame(minWidth: 520, minHeight: 320)
                .environmentObject(model)
        }
        .windowResizability(.contentSize)
    }
}
