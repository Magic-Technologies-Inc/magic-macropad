import SwiftUI
import MagicKeysCore

extension KeyModifier {
    var symbol: String {
        switch self {
        case .command: return "⌘"
        case .shift: return "⇧"
        case .option: return "⌥"
        case .control: return "⌃"
        }
    }
}

extension MediaCommand {
    var label: String {
        switch self {
        case .playPause: return "Play / Pause"
        case .previousTrack: return "Previous Track"
        case .nextTrack: return "Next Track"
        case .volumeUp: return "Volume Up"
        case .volumeDown: return "Volume Down"
        case .mute: return "Mute"
        }
    }
    var icon: String {
        switch self {
        case .playPause: return "playpause.fill"
        case .previousTrack: return "backward.fill"
        case .nextTrack: return "forward.fill"
        case .volumeUp: return "speaker.wave.2.fill"
        case .volumeDown: return "speaker.wave.1.fill"
        case .mute: return "speaker.slash.fill"
        }
    }
}

extension SystemCommand {
    var label: String {
        switch self {
        case .switchApp: return "Switch App (⌘Tab)"
        case .toggleMicMute: return "Mute / Unmute Mic"
        case .lockScreen: return "Lock Screen"
        case .sleepDisplay: return "Sleep Display"
        case .toggleDarkMode: return "Toggle Dark Mode"
        case .screenshotRegion: return "Screenshot Region"
        case .missionControl: return "Mission Control"
        case .toggleKeepAwake: return "Keep Awake"
        }
    }
    var icon: String {
        switch self {
        case .switchApp: return "macwindow.on.rectangle"
        case .toggleMicMute: return "mic.slash.fill"
        case .lockScreen: return "lock.fill"
        case .sleepDisplay: return "display"
        case .toggleDarkMode: return "circle.lefthalf.filled"
        case .screenshotRegion: return "camera.viewfinder"
        case .missionControl: return "square.grid.3x3.fill"
        case .toggleKeepAwake: return "cup.and.saucer.fill"
        }
    }
}

extension AICommand {
    var label: String {
        switch self {
        case .newClaudeChat: return "New Claude Chat"
        case .newChatGPTChat: return "New ChatGPT Chat"
        case .dictation: return "Dictation"
        }
    }
    var icon: String {
        switch self {
        case .newClaudeChat: return "sparkle"
        case .newChatGPTChat: return "bubble.left.and.text.bubble.right"
        case .dictation: return "mic.fill"
        }
    }
}

extension ActionConfig {
    /// SF Symbol shown in the gesture row and picker.
    var icon: String {
        switch self {
        case .openApp: return "app.dashed"
        case .openURL: return "safari"
        case .openPath: return "folder"
        case .keystroke: return "keyboard"
        case .media(let command): return command.icon
        case .pasteText: return "doc.on.clipboard"
        case .system(let command): return command.icon
        case .ai(let command): return command.icon
        case .shellScript: return "terminal"
        }
    }

    /// The primary name shown in a gesture row.
    var name: String {
        switch self {
        case .openApp(let bundleID):
            return bundleID.isEmpty ? "Open App" : (appName(forBundleID: bundleID) ?? "Open App")
        case .openURL(let urlString):
            return urlString.isEmpty ? "Open URL" : displayURL(urlString)
        case .openPath(let path):
            return path.isEmpty ? "Open File / Folder" : (path as NSString).lastPathComponent
        case .keystroke:
            return "Keystroke"
        case .media(let command):
            return command.label
        case .pasteText(let text):
            return text.isEmpty ? "Paste Text" : text
        case .system(let command):
            return command.label
        case .ai(let command):
            return command.label
        case .shellScript(let script, let name):
            if let name, !name.isEmpty { return name }
            return script.isEmpty ? "Shell Script" : script
        }
    }

    /// The right-aligned monospace hint (a shortcut or short descriptor).
    var shortcutHint: String {
        switch self {
        case .keystroke(let keyCode, let modifiers):
            return modifiers.map(\.symbol).joined() + KeyName.forCode(keyCode)
        case .openApp, .openURL, .openPath, .media, .pasteText, .system, .ai, .shellScript:
            return ""
        }
    }

    private func displayURL(_ s: String) -> String {
        guard let host = URL(string: s)?.host else { return s }
        return host
    }

    private func appName(forBundleID bundleID: String) -> String? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }
}

/// The picker's action catalog: parameterised types plus ready-made media commands.
enum ActionType: String, CaseIterable, Identifiable {
    case openApp, openURL, openFile, keystroke, pasteText, shellScript
    var id: String { rawValue }
    var title: String {
        switch self {
        case .openApp: return "Open App…"
        case .openURL: return "Open URL…"
        case .openFile: return "Open File / Folder…"
        case .keystroke: return "Keystroke…"
        case .pasteText: return "Paste Text…"
        case .shellScript: return "Shell Script…"
        }
    }
    var icon: String {
        switch self {
        case .openApp: return "app.dashed"
        case .openURL: return "safari"
        case .openFile: return "folder"
        case .keystroke: return "keyboard"
        case .pasteText: return "doc.on.clipboard"
        case .shellScript: return "terminal"
        }
    }
}

/// Minimal key-code → name map for displaying keystroke hints.
enum KeyName {
    static func forCode(_ code: UInt16) -> String {
        let map: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
            31: "O", 35: "P", 37: "L", 45: "N", 46: "M",
            49: "Space", 36: "↩", 48: "⇥", 53: "⎋", 51: "⌫",
            123: "←", 124: "→", 125: "↓", 126: "↑",
        ]
        return map[code] ?? "\(code)"
    }
}
