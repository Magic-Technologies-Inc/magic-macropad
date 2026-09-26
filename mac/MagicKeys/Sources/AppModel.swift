import AppKit
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

    let configStore: ConfigStore
    let frontApps = FrontAppMonitor()
    private let actionEngine = ActionEngine()
    private let easterEgg = EasterEgg()
    private let hidService = HIDService()
    private var pipeline: GesturePipeline?
    private var observers: [AnyCancellable] = []

    init(configStore: ConfigStore = ConfigStore()) {
        self.configStore = configStore
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

    struct RunningApp: Identifiable, Equatable {
        let id: String       // bundle id
        let name: String
    }

    /// Running regular apps that don't already have a profile, for the add menu.
    func addableApps() -> [RunningApp] {
        let existing = Set(configStore.config.profiles.compactMap { $0.bundleID })
        let selfID = Bundle.main.bundleIdentifier
        var seen = Set<String>()
        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> RunningApp? in
                guard let id = app.bundleIdentifier, id != selfID,
                      !existing.contains(id), seen.insert(id).inserted,
                      let name = app.localizedName else { return nil }
                return RunningApp(id: id, name: name)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Adds a profile for a specific app and selects it.
    func addProfile(bundleID: String, name: String) {
        configStore.update { $0.addProfile(bundleID: bundleID, name: name, symbol: "app.badge") }
        editingProfileID = bundleID
    }

    /// Opens a file picker to add a profile for any installed app.
    func addProfileByChoosingApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url,
              let bundle = Bundle(url: url), let id = bundle.bundleIdentifier else { return }
        let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
        addProfile(bundleID: id, name: name)
    }

    func removeProfile(id: String) {
        configStore.update { $0.removeProfile(id: id) }
        if editingProfileID == id { editingProfileID = configStore.config.defaultProfile.id }
    }


    func start() {
        if let backup = configStore.unreadableConfigBackup {
            actionEngine.notifyInfo("Your settings file couldn't be read, so Magic Macropad started from its default bindings. The old file was kept as \(backup.lastPathComponent) in \(backup.deletingLastPathComponent().path).")
        }
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
        pipeline.onChord = { [weak self] in self?.easterEgg.fire() }
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

    private var virtualSeq: UInt8 = 0
    /// Simulates a physical press: down now, up after `duration`. Exposed in all
    /// builds so the in-app "Test keys" menu works without hardware.
    func simulatePress(key: Int, duration: TimeInterval = 0.1) {
        virtualSeq &+= 1
        pipeline?.handle(KeyEvent(key: key, isDown: true, seq: virtualSeq))
        virtualSeq &+= 1
        let seq = virtualSeq
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.pipeline?.handle(KeyEvent(key: key, isDown: false, seq: seq))
        }
    }

    #if DEBUG
    /// Presses all three keys together, then releases them — to test the
    /// all-keys easter egg without hardware.
    func simulateChord() {
        for key in 0..<K1Protocol.keyCount {
            virtualSeq &+= 1
            pipeline?.handle(KeyEvent(key: key, isDown: true, seq: virtualSeq))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self else { return }
            for key in 0..<K1Protocol.keyCount {
                self.virtualSeq &+= 1
                self.pipeline?.handle(KeyEvent(key: key, isDown: false, seq: self.virtualSeq))
            }
        }
    }
    #endif
}
