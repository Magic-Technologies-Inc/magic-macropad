import Combine
import Foundation
import MagicKeysCore

@MainActor
final class AppModel: ObservableObject {
    @Published var isConnected = false
    @Published var deviceInfo: DeviceInfo?
    @Published var lastGesture: Gesture?

    let configStore = ConfigStore()
    private let actionEngine = ActionEngine()
    private let hidService = HIDService()
    private var pipeline: GesturePipeline?
    private var configObserver: AnyCancellable?

    init() {
        // ConfigStore is a nested ObservableObject; SwiftUI views observe AppModel,
        // not it. Forward its changes so config edits re-render the UI immediately
        // instead of waiting for the next unrelated invalidation.
        configObserver = configStore.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    func start() {
        pipeline = makePipeline()

        hidService.onConnectionChange = { [weak self] connected in
            Task { @MainActor in
                self?.isConnected = connected
                if !connected {
                    self?.deviceInfo = nil
                    // Drop in-flight gesture state (spec: reset on disconnect).
                    self?.pipeline = self?.makePipeline()
                }
            }
        }
        hidService.onMessage = { [weak self] message in
            Task { @MainActor in self?.handle(message) }
        }
        hidService.start()
    }

    private func makePipeline() -> GesturePipeline {
        let pipeline = GesturePipeline(timing: configStore.config.timing)
        pipeline.onGesture = { [weak self] gesture in
            guard let self else { return }
            self.lastGesture = gesture
            if let action = self.configStore.config.action(for: gesture) {
                self.actionEngine.run(action)
            }
        }
        return pipeline
    }

    private func handle(_ message: K1Message) {
        switch message {
        case .info(let info): deviceInfo = info
        case .keyEvent(let event): pipeline?.handle(event)
        }
    }

    #if DEBUG
    private var virtualSeq: UInt8 = 0
    /// Simulates a physical press: down now, up after `duration`.
    func simulatePress(key: Int, duration: TimeInterval = 0.1) {
        virtualSeq &+= 1
        pipeline?.handle(KeyEvent(key: key, isDown: true, seq: virtualSeq))
        virtualSeq &+= 1
        let seq = virtualSeq
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.pipeline?.handle(KeyEvent(key: key, isDown: false, seq: seq))
        }
    }
    #endif
}
