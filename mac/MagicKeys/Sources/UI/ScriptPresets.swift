import Foundation

/// A ready-made shell script the user can drop into the Shell Script action and
/// tweak. Kept dependency-light on purpose — everything here runs on a stock
/// macOS install except the one that says it needs `blueutil`.
struct ScriptPreset: Identifiable {
    var id: String { name }
    let name: String
    let script: String
}

enum ScriptPresets {
    static let all: [ScriptPreset] = [
        ScriptPreset(
            name: "Toggle Desktop Icons",
            script: #"current=$(defaults read com.apple.finder CreateDesktop 2>/dev/null); if [ "$current" = "0" ]; then defaults write com.apple.finder CreateDesktop -bool true; else defaults write com.apple.finder CreateDesktop -bool false; fi; killall Finder"#),
        ScriptPreset(
            name: "Toggle Hidden Files",
            script: #"current=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null); if [ "$current" = "1" ] || [ "$current" = "YES" ]; then defaults write com.apple.finder AppleShowAllFiles -bool false; else defaults write com.apple.finder AppleShowAllFiles -bool true; fi; killall Finder"#),
        ScriptPreset(
            name: "Empty Trash",
            script: #"osascript -e 'tell application "Finder" to empty trash'"#),
        ScriptPreset(
            name: "Eject All Disks",
            script: #"osascript -e 'tell application "Finder" to eject (every disk whose ejectable is true)'"#),
        ScriptPreset(
            name: "Copy Wi-Fi Name",
            script: #"networksetup -getairportnetwork en0 | sed 's/^Current Wi-Fi Network: //' | pbcopy"#),
        ScriptPreset(
            name: "Timestamp → Clipboard",
            script: #"date '+%Y-%m-%d %H:%M' | pbcopy"#),
        ScriptPreset(
            name: "New Note from Clipboard",
            script: #"osascript -e 'tell application "Notes" to make new note with properties {body:(the clipboard as text)}'"#),
        ScriptPreset(
            name: "Git: Commit & Push (edit path)",
            script: #"cd ~/Developer/Magic/K1 && git add -A && git commit -m "wip: $(date '+%F %H:%M')" && git push"#),
        ScriptPreset(
            name: "Toggle Bluetooth (needs blueutil)",
            script: #"blueutil -p toggle"#),
    ]
}
