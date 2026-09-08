import Foundation
import MagicKeysCore

@MainActor
final class AppModel: ObservableObject {
    @Published var isConnected = false
    @Published var deviceInfo: DeviceInfo?

    let configStore = ConfigStore()

    // HIDService / GesturePipeline / ActionEngine attach in later tasks.
    func start() {}
}
