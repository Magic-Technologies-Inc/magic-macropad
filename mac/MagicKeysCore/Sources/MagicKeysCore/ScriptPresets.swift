import Foundation

/// A ready-made shell script the user can drop into the Shell Script action and
/// tweak. Grouped into `category` submenus in the picker. Kept dependency-light,
/// except a few that use tools the user likely already has (`claude`, `cursor`,
/// `gh`, `blueutil`) — those note the requirement.
public struct ScriptPreset: Identifiable, Equatable, Sendable {
    public var id: String { name }
    public let name: String
    public let category: String
    public let script: String
}

public enum ScriptPresets {
    /// Also the seeded key-3 triple tap (see K1Config.makeSeeded).
    public static let improveWriting = ScriptPreset(
        name: "Improve Writing", category: "AI · Clipboard",
        script: clipboardThroughClaude(
            "Fix grammar and tighten this. Return only the revised text, no preamble.",
            done: "Rewritten — ⌘V to paste"))

    public static let all: [ScriptPreset] = [
        // MARK: AI · Clipboard — pipe the clipboard through Claude, result back on the clipboard.
        improveWriting,
        ScriptPreset(
            name: "Explain Clipboard", category: "AI · Clipboard",
            script: clipboardThroughClaude("Explain this clearly and concisely.",
                                           done: "Explanation copied — ⌘V")),
        ScriptPreset(
            name: "Summarize to Bullets", category: "AI · Clipboard",
            script: clipboardThroughClaude("Summarize this in 3-5 tight bullet points.",
                                           done: "Summary copied — ⌘V")),
        ScriptPreset(
            name: "Explain This Error", category: "AI · Clipboard",
            script: clipboardThroughClaude("Explain this error and give the most likely fix.",
                                           done: "Fix copied — ⌘V")),

        // MARK: AI · Coding
        // Values reach AppleScript as `argv` (and the shell via `quoted form of`),
        // never spliced into script source, so quotes in them can't break out.
        ScriptPreset(
            name: "New Claude Session Here", category: "AI · Coding",
            script: #"""
            # Requires the Claude CLI (claude). Opens it in the front Finder window's folder.
            dir=$(osascript -e 'tell application "Finder" to POSIX path of (insertion location as alias)') || exit
            osascript - "$dir" <<'EOF'
            on run argv
                tell application "Terminal"
                    do script "cd " & quoted form of (item 1 of argv) & " && claude"
                    activate
                end tell
            end run
            EOF
            """#),
        ScriptPreset(
            name: "AI Commit", category: "AI · Coding",
            script: #"""
            # Requires the Claude CLI (claude). Edit the repo path for your project.
            cd ~/Developer/your-project || exit
            git add -A || exit
            msg=$(git diff --cached | claude -p "Write a one-line conventional-commit message for this diff. Output only the message.") || exit
            [ -n "$msg" ] || { echo "Claude returned an empty commit message" >&2; exit 1; }
            git commit -m "$msg" || exit
            osascript - "$msg" <<'EOF'
            on run argv
                display notification (item 1 of argv) with title "Committed"
            end run
            EOF
            """#),

        // MARK: Git (edit the repo path)
        ScriptPreset(
            name: "Copy Git Diff", category: "Git",
            script: #"""
# Edit the repo path for your project
cd ~/Developer/your-project && git diff | pbcopy && osascript -e 'display notification "Diff copied — ⌘V" with title "Clipboard"'
"""#),
        ScriptPreset(
            name: "Git: Commit & Push", category: "Git",
            script: #"""
# Edit the repo path for your project
cd ~/Developer/your-project && git add -A && git commit -m "wip: $(date '+%F %H:%M')" && git push
"""#),
        ScriptPreset(
            name: "Open Repo on GitHub", category: "Git",
            script: #"""
# Requires the GitHub CLI (gh). Edit the repo path for your project.
cd ~/Developer/your-project && gh browse
"""#),
        ScriptPreset(
            name: "Copy Branch Name", category: "Git",
            script: #"""
# Edit the repo path for your project
cd ~/Developer/your-project && git branch --show-current | pbcopy
"""#),

        // MARK: Editor & Finder
        ScriptPreset(
            name: "Open Folder in Cursor", category: "Editor & Finder",
            script: #"""
# Requires Cursor's shell command (cursor).
d=$(osascript -e 'tell application "Finder" to POSIX path of (insertion location as alias)'); cursor "$d"
"""#),

        // MARK: System
        ScriptPreset(
            name: "Toggle Desktop Icons", category: "System",
            script: #"current=$(defaults read com.apple.finder CreateDesktop 2>/dev/null); if [ "$current" = "0" ]; then defaults write com.apple.finder CreateDesktop -bool true; else defaults write com.apple.finder CreateDesktop -bool false; fi; killall Finder"#),
        ScriptPreset(
            name: "Toggle Hidden Files", category: "System",
            script: #"current=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null); if [ "$current" = "1" ] || [ "$current" = "YES" ]; then defaults write com.apple.finder AppleShowAllFiles -bool false; else defaults write com.apple.finder AppleShowAllFiles -bool true; fi; killall Finder"#),
        ScriptPreset(
            name: "Empty Trash", category: "System",
            script: #"osascript -e 'tell application "Finder" to empty trash'"#),
        ScriptPreset(
            name: "Eject All Disks", category: "System",
            script: #"osascript -e 'tell application "Finder" to eject (every disk whose ejectable is true)'"#),
        ScriptPreset(
            name: "Copy Wi-Fi Name", category: "System",
            script: #"networksetup -getairportnetwork en0 | sed 's/^Current Wi-Fi Network: //' | pbcopy"#),
        ScriptPreset(
            name: "Timestamp → Clipboard", category: "System",
            script: #"date '+%Y-%m-%d %H:%M' | pbcopy"#),
        ScriptPreset(
            name: "New Note from Clipboard", category: "System",
            script: #"osascript -e 'tell application "Notes" to make new note with properties {body:(the clipboard as text)}'"#),
        ScriptPreset(
            name: "Toggle Bluetooth", category: "System",
            script: #"""
# Requires blueutil (brew install blueutil)
blueutil -p toggle
"""#),
    ]

    /// Presets grouped by category, preserving first-seen order for both.
    public static var byCategory: [(category: String, presets: [ScriptPreset])] {
        var order: [String] = []
        var groups: [String: [ScriptPreset]] = [:]
        for preset in all {
            if groups[preset.category] == nil { order.append(preset.category) }
            groups[preset.category, default: []].append(preset)
        }
        return order.map { ($0, groups[$0]!) }
    }

    /// The name to show after picking `preset` from the Examples menu. A name the
    /// user typed is kept; an empty one, or one that came from another example,
    /// follows the new pick so the label always describes the script it runs.
    public static func name(afterPicking preset: ScriptPreset, currentName: String) -> String {
        let isExampleName = currentName.isEmpty || all.contains { $0.name == currentName }
        return isExampleName ? preset.name : currentName
    }

    /// Pipes the clipboard through `claude -p` and puts the answer back — only
    /// once Claude has actually answered. A missing, offline or logged-out CLI
    /// leaves the clipboard untouched and exits non-zero, so the app reports it.
    private static func clipboardThroughClaude(_ prompt: String, done notice: String) -> String {
        """
        # Requires the Claude CLI (claude). The clipboard is only replaced once Claude answers.
        out=$(pbpaste | claude -p "\(prompt)") || exit
        [ -n "$out" ] || { echo "Claude returned an empty answer" >&2; exit 1; }
        printf '%s' "$out" | pbcopy
        osascript -e 'display notification "\(notice)" with title "Claude"'
        """
    }
}
