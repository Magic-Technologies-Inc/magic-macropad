import SwiftUI
import MagicKeysCore

/// Popover editor for one gesture slot: action type + parameters.
struct ActionEditorView: View {
    let title: String
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
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(MagicFont.text(11, weight: .semibold))
                .kerning(1.4)
                .foregroundStyle(MagicColor.textSecondary)

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

            parameterFields
        }
        .font(MagicFont.text(13))
        .padding(20)
        .frame(width: 340)
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
                TextField("Key code", value: Binding(
                    get: { keyCode },
                    set: { action = .keystroke(keyCode: $0, modifiers: modifiers) }),
                    format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                HStack(spacing: 12) {
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
        case .shellScript(let script):
            TextField("Shell command", text: Binding(
                get: { script },
                set: { action = .shellScript(script: $0) }))
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        case nil:
            Text("This key does nothing on \(title.lowercased()).")
                .font(MagicFont.text(12))
                .foregroundStyle(MagicColor.textTertiary)
        }
    }
}
