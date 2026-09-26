import AppKit
import Combine

/// Tracks the frontmost application so bindings can switch per app (Logi
/// Options+ style). Ignores Magic Macropad itself, so opening the popover doesn't
/// make Magic Macropad the "current app".
@MainActor
final class FrontAppMonitor: ObservableObject {
    struct FrontApp: Equatable {
        var bundleID: String
        var name: String
    }

    @Published private(set) var frontApp: FrontApp?

    private var observer: NSObjectProtocol?
    private let selfBundleID = Bundle.main.bundleIdentifier

    init() {
        update(NSWorkspace.shared.frontmostApplication)
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated { self?.update(app) }
        }
    }

    deinit {
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
    }

    private func update(_ app: NSRunningApplication?) {
        guard let app, let bundleID = app.bundleIdentifier, bundleID != selfBundleID else { return }
        frontApp = FrontApp(bundleID: bundleID, name: app.localizedName ?? bundleID)
    }

    /// The bundle id to resolve a gesture against, read live at press time. When
    /// Magic Macropad itself is frontmost (popover open), fall back to the last real app.
    var currentBundleID: String? {
        let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        return (front == nil || front == selfBundleID) ? frontApp?.bundleID : front
    }

    func icon(forBundleID bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}
