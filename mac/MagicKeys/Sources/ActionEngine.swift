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

        case .pasteText(let text):
            // Put the text on the pasteboard and synthesize ⌘V into the front app.
            guard ensureAccessibility() else { return }
            pasteText(text)

        case .system(let command):
            runSystem(command)

        case .ai(let command):
            runAI(command)

        case .shellScript(let script, _):
            runShell(script)
        }
    }

    // MARK: AI actions

    private func runAI(_ command: AICommand) {
        switch command {
        case .newClaudeChat:
            if let url = URL(string: "https://claude.ai/new") { NSWorkspace.shared.open(url) }

        case .newChatGPTChat:
            // Prefer the ChatGPT app if installed; fall back to the web.
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.openai.chat") {
                NSWorkspace.shared.openApplication(at: appURL, configuration: .init())
            } else if let url = URL(string: "https://chatgpt.com") {
                NSWorkspace.shared.open(url)
            }

        case .dictation:
            // F5 is the Dictation key on modern Mac keyboards; posting it starts
            // Dictation when that (default) shortcut is in effect.
            guard ensureAccessibility() else { return }
            postKeystroke(keyCode: 96, modifiers: [])  // kVK_F5
        }
    }

    // MARK: Paste Text

    private func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        // Let the pasteboard settle before the keystroke, or the front app can
        // paste stale contents.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.postKeystroke(keyCode: 9, modifiers: [.command])  // V
        }
    }

    // MARK: System actions

    /// A caffeinate process kept alive while "keep awake" is toggled on.
    private var keepAwakeProcess: Process?

    private func runSystem(_ command: SystemCommand) {
        switch command {
        case .switchApp:
            guard ensureAccessibility() else { return }
            postAppSwitch()

        case .toggleMicMute:
            // Standard Additions volume commands — no Automation permission.
            runOSAScript([
                "if (input volume of (get volume settings)) > 0 then",
                "set volume input volume 0",
                "else",
                "set volume input volume 100",
                "end if",
            ])
        case .lockScreen:
            guard ensureAccessibility() else { return }
            postKeystroke(keyCode: 12, modifiers: [.command, .control])  // ⌃⌘Q = Q

        case .sleepDisplay:
            runProcess("/usr/bin/pmset", ["displaysleepnow"])

        case .toggleDarkMode:
            runOSAScript(["tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode"])

        case .screenshotRegion:
            runProcess("/usr/sbin/screencapture", ["-ic"])  // interactive region → clipboard

        case .missionControl:
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Mission Control.app"))

        case .toggleKeepAwake:
            toggleKeepAwake()
        }
    }

    private func toggleKeepAwake() {
        if let process = keepAwakeProcess, process.isRunning {
            process.terminate()
            keepAwakeProcess = nil
            notifyInfo("Sleep allowed — Magic Keys is no longer keeping this Mac awake.")
        } else {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
            process.arguments = ["-dimsu"]  // display, idle, disk, system; keep awake
            do {
                try process.run()
                keepAwakeProcess = process
                notifyInfo("Keeping this Mac awake — tap again to allow sleep.")
            } catch {
                notifyFailure("Couldn't start caffeinate: \(error.localizedDescription)")
            }
        }
    }

    private func runOSAScript(_ lines: [String]) {
        var args: [String] = []
        for line in lines { args.append("-e"); args.append(line) }
        runProcess("/usr/bin/osascript", args)
    }

    private func runProcess(_ path: String, _ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        do {
            try process.run()
        } catch {
            notifyFailure("Couldn't run \((path as NSString).lastPathComponent): \(error.localizedDescription)")
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

    /// Synthesizes ⌘Tab as a real hold-⌘ / tap-Tab / release-⌘ sequence. A plain
    /// keystroke won't do it: the app switcher only commits when the Command flag
    /// drops, so Command must be pressed and released around the Tab tap.
    private func postAppSwitch() {
        let source = CGEventSource(stateID: .hidSystemState)
        let command: CGKeyCode = 0x37  // left Command
        let tab: CGKeyCode = 0x30
        func post(_ key: CGKeyCode, down: Bool, flags: CGEventFlags) {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: down) else { return }
            event.flags = flags
            event.post(tap: .cghidEventTap)
        }
        post(command, down: true, flags: .maskCommand)
        post(tab, down: true, flags: .maskCommand)
        post(tab, down: false, flags: .maskCommand)
        post(command, down: false, flags: [])
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
        postNotification(message)
    }

    /// A neutral status notification (e.g. a toggle's new state), so actions with
    /// no visible effect still confirm they ran.
    private func notifyInfo(_ message: String) {
        postNotification(message)
    }

    private func postNotification(_ message: String) {
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
