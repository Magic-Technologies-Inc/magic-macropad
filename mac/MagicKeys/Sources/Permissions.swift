import AppKit
import ApplicationServices
import UserNotifications

/// Requests the permissions Magic Keys needs to synthesize key/media events and
/// post failure notifications. Also clears any stale Accessibility grant left by
/// a previously-installed build of the app (the grant is keyed to the exact code
/// signature, so a rebuilt binary at the same path is often "listed but not
/// trusted" until the old entry is cleared and re-granted).
@MainActor
enum Permissions {
    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// One-click flow: clear the old grant, then prompt for Accessibility and
    /// Notifications and open the Accessibility settings pane to toggle it on.
    ///
    /// System Settings is quit first so the Privacy list reopens fresh — the
    /// pane caches its rows and will otherwise show a stale "on" toggle for the
    /// entry we just cleared, which is misleading (a dev rebuild's signature no
    /// longer matches, so the running process is actually untrusted until the
    /// user re-enables it).
    static func requestAll() {
        resetAccessibilityGrant()
        promptAccessibility()
        requestNotifications()
        quitSystemSettings()
        // Let System Settings fully terminate before reopening, so the pane
        // loads a fresh list rather than the cached one it was just showing.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            openAccessibilitySettings()
        }
    }

    /// Quits System Settings (and its legacy name) so it can't show a cached
    /// snapshot of the Accessibility list when we reopen it.
    private static func quitSystemSettings() {
        for name in ["System Settings", "System Preferences"] {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            process.arguments = [name]
            try? process.run()
            process.waitUntilExit()
        }
    }

    /// `tccutil reset` removes this bundle id from the Accessibility list, so the
    /// next prompt re-adds a fresh entry for the current binary.
    private static func resetAccessibilityGrant() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", "Accessibility", bundleID]
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            NSLog("MagicKeys: tccutil reset failed: \(error)")
        }
    }

    private static func promptAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private static func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
