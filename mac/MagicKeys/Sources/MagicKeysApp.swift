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
                .task { model.start() }
        }

        Window("Magic Keys", id: "config") {
            ConfigView()
                .environmentObject(model)
        }
        .windowResizability(.contentSize)
    }
}
