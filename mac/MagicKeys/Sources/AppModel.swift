import Combine
import Foundation
import MagicKeysCore

@MainActor
final class AppModel: ObservableObject {
    @Published var isConnected = false
    @Published var deviceInfo: DeviceInfo?
    @Published var lastGesture: Gesture?

    /// Which profile the config UI is currently editing (chip selection).
    @Published var editingProfileID: String

    let configStore = ConfigStore()
    let frontApps = FrontAppMonitor()
    private let actionEngine = ActionEngine()
    private let hidService = HIDService()
    private var pipeline: GesturePipeline?
    private var observers: [AnyCancellable] = []

    init() {
        editingProfileID = configStore.config.defaultProfile.id
        // ConfigStore and FrontAppMonitor are nested ObservableObjects; SwiftUI
        // views observe AppModel, not them. Forward their changes so config edits
        // and app switches re-render the UI immediately.
        configStore.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &observers)
        frontApps.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &observers)
    }

    // MARK: Profile editing (config UI)

    /// The profile currently being edited; falls back to default if it was removed.
    var editingProfile: AppProfile {
        configStore.config.profiles.first { $0.id == editingProfileID } ?? configStore.config.defaultProfile
    }

    func selectProfile(id: String) {
        editingProfileID = id
    }

    /// Adds a profile for the frontmost app (if any) and selects it.
    func addProfileForFrontApp() {
        guard let front = frontApps.frontApp else { return }
        let symbol = "app.badge"
        configStore.update { $0.addProfile(bundleID: front.bundleID, name: front.name, symbol: symbol) }
        editingProfileID = front.bundleID
    }

    func removeProfile(id: String) {
        configStore.update { $0.removeProfile(id: id) }
        if editingProfileID == id { editingProfileID = configStore.config.defaultProfile.id }
    }

    /// Copies the editing profile's key bindings into every other profile.
    func copyEditingProfileToAll() {
        let keys = editingProfile.keys
        configStore.update { config in
            for i in config.profiles.indices where config.profiles[i].id != editingProfileID {
                config.profiles[i].keys = keys
            }
        }
    }

    func clearEditingKey(_ keyIndex: Int) {
        configStore.update { config in
            guard let i = config.profileIndex(id: editingProfileID),
                  config.profiles[i].keys.indices.contains(keyIndex) else { return }
            config.profiles[i].keys[keyIndex] = KeyBinding()
        }
    }

    /// Whether the frontmost app already has a profile (to gate "Add app").
    var frontAppHasProfile: Bool {
        guard let bundleID = frontApps.frontApp?.bundleID else { return true }
        return configStore.config.profiles.contains { $0.bundleID == bundleID }
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
            // Resolve against the profile for whatever app is frontmost right now.
            let bundleID = self.frontApps.currentBundleID
            if let action = self.configStore.config.action(for: gesture, bundleID: bundleID) {
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
