import Foundation
import MagicKeysCore

@MainActor
final class AppModel: ObservableObject {
    @Published var isConnected = false
    @Published var deviceInfo: DeviceInfo?

    let configStore = ConfigStore()
    private let hidService = HIDService()

    func start() {
        hidService.onConnectionChange = { [weak self] connected in
            Task { @MainActor in
                self?.isConnected = connected
                if !connected { self?.deviceInfo = nil }
            }
        }
        hidService.onMessage = { [weak self] message in
            Task { @MainActor in self?.handle(message) }
        }
        hidService.start()
    }

    private func handle(_ message: K1Message) {
        switch message {
        case .info(let info):
            deviceInfo = info
        case .keyEvent(let event):
            NSLog("MagicKeys: key \(event.key) \(event.isDown ? "down" : "up")")
            // GesturePipeline consumes these in Task 8.
        }
    }
}
