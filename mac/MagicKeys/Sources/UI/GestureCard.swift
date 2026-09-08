import SwiftUI
import MagicKeysCore

extension ActionConfig {
    var iconName: String {
        switch self {
        case .openApp: return "app.dashed"
        case .openURL: return "safari"
        case .keystroke: return "keyboard"
        case .media: return "playpause"
        case .shellScript: return "terminal"
        }
    }

    var summary: String {
        switch self {
        case .openApp(let bundleID):
            return bundleID.isEmpty ? "Open App" : "Open \(bundleID)"
        case .openURL(let urlString):
            return urlString.isEmpty ? "Open URL" : urlString
        case .keystroke(let keyCode, let modifiers):
            let mods = modifiers.map(\.symbol).joined()
            return "Keystroke \(mods)\(keyCode)"
        case .media(let command):
            return command.label
        case .shellScript(let script):
            return script.isEmpty ? "Shell Script" : script
        }
    }
}

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
        case .volumeUp: return "Volume Up"
        case .volumeDown: return "Volume Down"
        case .mute: return "Mute"
        }
    }
}

/// One gesture slot (Tap / Double Tap / Hold) shown as a card. Clicking it
/// opens the action editor in a popover.
struct GestureCard: View {
    let title: String
    let gestureIcon: String
    @Binding var action: ActionConfig?
    @State private var isEditing = false
    @State private var isHovered = false

    private var isAssigned: Bool { action != nil }

    var body: some View {
        Button {
            isEditing.toggle()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isAssigned ? MagicColor.cerulean.opacity(0.16) : MagicColor.surfaceSunken)
                        .frame(width: 40, height: 40)
                    Image(systemName: action?.iconName ?? gestureIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isAssigned ? MagicColor.cerulean : MagicColor.textTertiary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title.uppercased())
                        .font(MagicFont.text(11, weight: .semibold))
                        .kerning(1.4)
                        .foregroundStyle(MagicColor.textSecondary)
                    Text(action?.summary ?? "Not assigned")
                        .font(MagicFont.text(14, weight: isAssigned ? .medium : .regular))
                        .foregroundStyle(isAssigned ? MagicColor.textPrimary : MagicColor.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MagicColor.textTertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MagicColor.surfaceCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isHovered ? MagicColor.slate300.opacity(0.5) : MagicColor.borderHairline,
                                  lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .popover(isPresented: $isEditing, arrowEdge: .trailing) {
            ActionEditorView(title: title, action: $action)
        }
    }
}
