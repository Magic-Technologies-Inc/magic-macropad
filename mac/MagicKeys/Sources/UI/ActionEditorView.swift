import SwiftUI
import MagicKeysCore

/// Inline editor for one gesture slot: action type + parameters. Rendered inside
/// the expanded GestureCard (no popover — see GestureCard).
struct ActionEditorView: View {
    @Binding var action: ActionConfig?

    private enum Kind: String, CaseIterable, Identifiable {
        case none = "None"
        case openApp = "Open App"
        case openURL = "Open URL"
        case keystroke = "Keystroke"
        case media = "Media"
        case shellScript = "Shell Script"
        var id: String { rawValue }
    }

    private var kind: Kind {
        switch action {
        case nil: return .none
        case .openApp: return .openApp
        case .openURL: return .openURL
        case .keystroke: return .keystroke
        case .media: return .media
        case .shellScript: return .shellScript
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACTION")
                    .font(MagicFont.text(10, weight: .semibold))
                    .kerning(1.3)
                    .foregroundStyle(MagicColor.textTertiary)
                Spacer()
                Picker("Action", selection: Binding(
                    get: { kind },
                    set: { newKind in
                        switch newKind {
                        case .none: action = nil
                        case .openApp: action = .openApp(bundleID: "")
                        case .openURL: action = .openURL(urlString: "")
                        case .keystroke: action = .keystroke(keyCode: 0, modifiers: [])
                        case .media: action = .media(command: .playPause)
                        case .shellScript: action = .shellScript(script: "")
                        }
                    })) {
                    ForEach(Kind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
            }
            parameterFields
        }
        .font(MagicFont.text(13))
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var parameterFields: some View {
        switch action {
        case .openApp(let bundleID):
            TextField("Bundle ID (e.g. com.apple.Music)", text: Binding(
                get: { bundleID },
                set: { action = .openApp(bundleID: $0) }))
                .textFieldStyle(.roundedBorder)
        case .openURL(let urlString):
            TextField("URL", text: Binding(
                get: { urlString },
                set: { action = .openURL(urlString: $0) }))
                .textFieldStyle(.roundedBorder)
        case .keystroke(let keyCode, let modifiers):
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Key code")
                        .foregroundStyle(MagicColor.textSecondary)
                    TextField("0", value: Binding(
                        get: { keyCode },
                        set: { action = .keystroke(keyCode: $0, modifiers: modifiers) }),
                        format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                }
                HStack(spacing: 8) {
                    ForEach(KeyModifier.allCases, id: \.self) { modifier in
                        Toggle(modifier.symbol, isOn: Binding(
                            get: { modifiers.contains(modifier) },
                            set: { on in
                                var updated = modifiers.filter { $0 != modifier }
                                if on { updated.append(modifier) }
                                action = .keystroke(keyCode: keyCode, modifiers: updated)
                            }))
                            .toggleStyle(.button)
                    }
                }
            }
        case .media(let command):
            Picker("Command", selection: Binding(
                get: { command },
                set: { action = .media(command: $0) })) {
                ForEach(MediaCommand.allCases, id: \.self) { command in
                    Text(command.label).tag(command)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()
        case .shellScript(let script):
            TextField("Shell command", text: Binding(
                get: { script },
                set: { action = .shellScript(script: $0) }))
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        case nil:
            Text("This gesture does nothing.")
                .font(MagicFont.text(12))
                .foregroundStyle(MagicColor.textTertiary)
        }
    }
}
