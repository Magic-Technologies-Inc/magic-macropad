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
            guard let url = URLInput.openable(urlString) else {
                notifyFailure("Invalid URL: \(urlString)")
                return
            }
            if !NSWorkspace.shared.open(url) { notifyFailure("Couldn't open \(urlString)") }

        case .openPath(let path):
            let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
            guard FileManager.default.fileExists(atPath: url.path) else {
                notifyFailure("No file or folder at \(path)")
                return
            }
            if !NSWorkspace.shared.open(url) { notifyFailure("Couldn't open \(path)") }

        case .keystroke(let keyCode, let modifiers):
            guard ensureAccessibility() else { return }
            whenFrontAppIsActive { [weak self] in self?.postKeystroke(keyCode: keyCode, modifiers: modifiers) }

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
            // Login shell for the user's PATH, plus the usual CLI tool folders.
            launch("/bin/zsh", ["-lc", script], name: "Script", environment: Self.shellEnvironment)
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
        whenFrontAppIsActive { [weak self] in
            // Let the pasteboard settle before the keystroke, or the front app can
            // paste stale contents.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self?.postKeystroke(keyCode: 9, modifiers: [.command])  // V
            }
        }
    }

    // MARK: System actions

    /// Held while "keep awake" is on. The system drops it when the app exits, so
    /// quitting or crashing can never leave the Mac unable to sleep.
    private var keepAwakeActivity: NSObjectProtocol?

    private func runSystem(_ command: SystemCommand) {
        let name = command.label
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
            ], name: name)
        case .lockScreen:
            guard ensureAccessibility() else { return }
            postKeystroke(keyCode: 12, modifiers: [.command, .control])  // ⌃⌘Q = Q

        case .sleepDisplay:
            launch("/usr/bin/pmset", ["displaysleepnow"], name: name)

        case .toggleDarkMode:
            runOSAScript(["tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode"],
                         name: name)

        case .screenshotRegion:
            // Interactive region → clipboard. Esc cancels with a non-zero exit,
            // which isn't a failure worth reporting.
            launch("/usr/sbin/screencapture", ["-ic"], name: name, checkStatus: false)

        case .missionControl:
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Mission Control.app"))

        case .toggleKeepAwake:
            toggleKeepAwake()
        }
    }

    private func toggleKeepAwake() {
        if let activity = keepAwakeActivity {
            ProcessInfo.processInfo.endActivity(activity)
            keepAwakeActivity = nil
            notifyInfo("Sleep allowed — Magic Macropad is no longer keeping this Mac awake.")
        } else {
            keepAwakeActivity = ProcessInfo.processInfo.beginActivity(
                options: [.idleDisplaySleepDisabled, .idleSystemSleepDisabled],
                reason: "Keep Awake action")
            notifyInfo("Keeping this Mac awake — tap again to allow sleep.")
        }
    }

    private func runOSAScript(_ lines: [String], name: String) {
        var args: [String] = []
        for line in lines { args.append("-e"); args.append(line) }
        launch("/usr/bin/osascript", args, name: name)
    }

    /// Runs a tool without blocking. A launch error — or, with `checkStatus`, a
    /// non-zero exit — becomes a failure notification naming the action.
    private func launch(_ path: String, _ arguments: [String], name: String,
                        environment: [String: String]? = nil, checkStatus: Bool = true) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        if let environment { process.environment = environment }
        if checkStatus {
            process.terminationHandler = { [weak self] process in
                let status = process.terminationStatus
                guard status != 0 else { return }
                Task { @MainActor in self?.notifyFailure(Self.exitMessage(name, status: status)) }
            }
        }
        do {
            try process.run()
        } catch {
            notifyFailure("Couldn't run \(name): \(error.localizedDescription)")
        }
    }

    private static func exitMessage(_ name: String, status: Int32) -> String {
        status == 127
            ? "\(name) failed: a command it uses isn't installed or isn't on the PATH."
            : "\(name) failed (exit status \(status))."
    }

    /// GUI apps start with a minimal PATH, and a login shell only adds what
    /// /etc/paths and ~/.zprofile provide — so also search where CLI tools like
    /// claude, gh and cursor usually live.
    private static var shellEnvironment: [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let extra = ["\(NSHomeDirectory())/.local/bin", "/opt/homebrew/bin", "/usr/local/bin"]
        environment["PATH"] = (extra + [environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"])
            .joined(separator: ":")
        return environment
    }

    /// Ensures Magic Macropad is trusted for Accessibility (required to synthesize
    /// key and media events), prompting on first use. Returns the trust state.
    private func ensureAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) { return true }
        notifyFailure("Allow Magic Macropad under System Settings → Privacy & Security → Accessibility, then try again.")
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

    // MARK: Synthesized input

    /// Keystrokes land in the key window of the active app. While our own panel
    /// is open that's Magic Macropad itself, so step aside first and post once
    /// the app the gesture was resolved for is frontmost again.
    private func whenFrontAppIsActive(_ post: @escaping @MainActor () -> Void) {
        guard NSApp.isActive else {
            post()
            return
        }
        let once = RunOnce(post)
        once.observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            guard app?.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
            MainActor.assumeIsolated { once.run() }
        }
        NSApp.hide(nil)
        // Fallback in case no other app takes over.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { once.run() }
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

    // MARK: Notifications

    private func notifyFailure(_ message: String) {
        NSLog("MagicKeys: action failed — \(message)")
        postNotification(message)
    }

    /// A neutral status notification (e.g. a toggle's new state), so actions with
    /// no visible effect still confirm they ran.
    func notifyInfo(_ message: String) {
        postNotification(message)
    }

    private func postNotification(_ message: String) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Magic Macropad"
            content.body = message
            UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }
}

/// Runs an action once, from whichever of several triggers fires first.
@MainActor
private final class RunOnce {
    var observer: NSObjectProtocol?
    private var action: (@MainActor () -> Void)?

    init(_ action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    func run() {
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        observer = nil
        let action = self.action
        self.action = nil
        action?()
    }
}
