import SwiftUI
import MagicKeysCore

/// Editor for one gesture slot: action type picker + parameters.
struct ActionPickerView: View {
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
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
            parameterFields
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
    }

    @ViewBuilder
    private var parameterFields: some View {
        switch action {
        case .openApp(let bundleID):
            TextField("Bundle ID (e.g. com.apple.Music)", text: Binding(
                get: { bundleID },
                set: { action = .openApp(bundleID: $0) }))
        case .openURL(let urlString):
            TextField("URL", text: Binding(
                get: { urlString },
                set: { action = .openURL(urlString: $0) }))
        case .keystroke(let keyCode, let modifiers):
            HStack {
                TextField("Key code", value: Binding(
                    get: { keyCode },
                    set: { action = .keystroke(keyCode: $0, modifiers: modifiers) }),
                    format: .number)
                    .frame(width: 80)
                ForEach(KeyModifier.allCases, id: \.self) { modifier in
                    Toggle(modifier.rawValue.capitalized, isOn: Binding(
                        get: { modifiers.contains(modifier) },
                        set: { on in
                            var updated = modifiers.filter { $0 != modifier }
                            if on { updated.append(modifier) }
                            action = .keystroke(keyCode: keyCode, modifiers: updated)
                        }))
                }
            }
        case .media(let command):
            Picker("Command", selection: Binding(
                get: { command },
                set: { action = .media(command: $0) })) {
                ForEach(MediaCommand.allCases, id: \.self) { command in
                    Text(command.rawValue).tag(command)
                }
            }
            .labelsHidden()
        case .shellScript(let script):
            TextField("Shell command", text: Binding(
                get: { script },
                set: { action = .shellScript(script: $0) }))
                .font(.system(.body, design: .monospaced))
        case nil:
            EmptyView()
        }
    }
}
