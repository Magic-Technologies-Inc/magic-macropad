import Foundation

/// A ready-made shell script the user can drop into the Shell Script action and
/// tweak. Grouped into `category` submenus in the picker. Kept dependency-light,
/// except a few that use tools the user likely already has (`claude`, `cursor`,
/// `gh`, `blueutil`) — those note the requirement.
struct ScriptPreset: Identifiable {
    var id: String { name }
    let name: String
    let category: String
    let script: String
}

enum ScriptPresets {
    static let all: [ScriptPreset] = [
        // MARK: AI · Clipboard — pipe the clipboard through Claude, result back on the clipboard.
        ScriptPreset(
            name: "Improve Writing", category: "AI · Clipboard",
            script: #"pbpaste | claude -p "Fix grammar and tighten this. Return only the revised text, no preamble." | pbcopy && osascript -e 'display notification "Rewritten — ⌘V to paste" with title "Claude"'"#),
        ScriptPreset(
            name: "Explain Clipboard", category: "AI · Clipboard",
            script: #"pbpaste | claude -p "Explain this clearly and concisely." | pbcopy && osascript -e 'display notification "Explanation copied — ⌘V" with title "Claude"'"#),
        ScriptPreset(
            name: "Summarize to Bullets", category: "AI · Clipboard",
            script: #"pbpaste | claude -p "Summarize this in 3-5 tight bullet points." | pbcopy && osascript -e 'display notification "Summary copied — ⌘V" with title "Claude"'"#),
        ScriptPreset(
            name: "Explain This Error", category: "AI · Clipboard",
            script: #"pbpaste | claude -p "Explain this error and give the most likely fix." | pbcopy && osascript -e 'display notification "Fix copied — ⌘V" with title "Claude"'"#),

        // MARK: AI · Coding
        ScriptPreset(
            name: "New Claude Session Here", category: "AI · Coding",
            script: #"d=$(osascript -e 'tell application "Finder" to POSIX path of (insertion location as alias)'); osascript -e "tell app \"Terminal\" to do script \"cd '$d' && claude\"" -e 'tell app "Terminal" to activate'"#),
        ScriptPreset(
            name: "AI Commit", category: "AI · Coding",
            script: #"""
# Edit the repo path for your project
cd ~/Developer/your-project && git add -A && msg=$(git diff --cached | claude -p "Write a one-line conventional-commit message for this diff. Output only the message.") && git commit -m "$msg" && osascript -e "display notification \"$msg\" with title \"Committed\""
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
# Edit the repo path for your project
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
            script: #"d=$(osascript -e 'tell application "Finder" to POSIX path of (insertion location as alias)'); cursor "$d""#),

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
    static var byCategory: [(category: String, presets: [ScriptPreset])] {
        var order: [String] = []
        var groups: [String: [ScriptPreset]] = [:]
        for preset in all {
            if groups[preset.category] == nil { order.append(preset.category) }
            groups[preset.category, default: []].append(preset)
        }
        return order.map { ($0, groups[$0]!) }
    }
}
