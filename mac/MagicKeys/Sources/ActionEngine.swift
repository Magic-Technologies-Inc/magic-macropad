import AppKit
import Foundation
import MagicKeysCore
import UserNotifications

/// Executes a configured action. Failures notify the user; they never throw
/// past this boundary.
@MainActor
final class ActionEngine {
    func run(_ action: ActionConfig) {
        switch action {
        case .openApp(let bundleID):
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
                notifyFailure("No app found for \(bundleID)")
                return
            }
            NSWorkspace.shared.openApplication(at: url, configuration: .init())

        case .openURL(let urlString):
            guard let url = URL(string: urlString) else {
                notifyFailure("Invalid URL: \(urlString)")
                return
            }
            NSWorkspace.shared.open(url)

        case .keystroke(let keyCode, let modifiers):
            guard ensureAccessibility() else { return }
            postKeystroke(keyCode: keyCode, modifiers: modifiers)

        case .media(let command):
            // Synthesized media-key events are only injected if the app is
            // trusted for Accessibility (same as keystrokes).
            guard ensureAccessibility() else { return }
            mediaKey(for: command).post()

        case .shellScript(let script):
            runShell(script)
        }
    }

    /// Ensures Magic Keys is trusted for Accessibility (required to synthesize
    /// key and media events), prompting on first use. Returns the trust state.
    private func ensureAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) { return true }
        notifyFailure("Allow Magic Keys under System Settings → Privacy & Security → Accessibility, then try again.")
        return false
    }

    private func mediaKey(for command: MediaCommand) -> MediaKey {
        switch command {
        case .playPause: return .playPause
        case .previousTrack: return .previousTrack
        case .nextTrack: return .nextTrack
        case .volumeUp: return .volumeUp
        case .volumeDown: return .volumeDown
        case .mute: return .mute
        }
    }

    private func postKeystroke(keyCode: UInt16, modifiers: [KeyModifier]) {
        var flags: CGEventFlags = []
        for modifier in modifiers {
            switch modifier {
            case .command: flags.insert(.maskCommand)
            case .shift: flags.insert(.maskShift)
            case .option: flags.insert(.maskAlternate)
            case .control: flags.insert(.maskControl)
            }
        }
        let source = CGEventSource(stateID: .hidSystemState)
        for down in [true, false] {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down) else { continue }
            event.flags = flags
            event.post(tap: .cghidEventTap)
        }
    }

    private func runShell(_ script: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", script]
        process.terminationHandler = { [weak self] process in
            if process.terminationStatus != 0 {
                Task { @MainActor in
                    self?.notifyFailure("Script exited with status \(process.terminationStatus)")
                }
            }
        }
        do {
            try process.run()
        } catch {
            notifyFailure("Could not run script: \(error.localizedDescription)")
        }
    }

    private func notifyFailure(_ message: String) {
        NSLog("MagicKeys: action failed — \(message)")
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Magic Keys"
            content.body = message
            center.add(UNNotificationRequest(identifier: UUID().uuidString,
                                             content: content, trigger: nil))
        }
    }
}
