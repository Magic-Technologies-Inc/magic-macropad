import AppKit
import SwiftUI
import MagicKeysCore

/// The action picker that drops in below the main card when a gesture row is
/// tapped: a list of actions, with an inline parameter step for the ones that
/// need configuring. Not a nested popover — it lives inside the panel.
struct ActionPickerSheet: View {
    let title: String
    let current: ActionConfig?
    let onSet: (ActionConfig?) -> Void
    let onClose: () -> Void

    private enum Stage: Equatable {
        case list
        case params(ActionType, ActionConfig)
    }
    @State private var stage: Stage = .list

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            switch stage {
            case .list: actionList
            case .params(let type, let draft): paramForm(type, draft)
            }
        }
        .padding(EdgeInsets(top: 14, leading: 12, bottom: 12, trailing: 12))
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(MagicColor.surfaceCard)
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(MagicColor.borderDefault, lineWidth: 1))
                .shadow(color: MagicColor.prussian.opacity(0.14), radius: 30, y: 12)
        )
    }

    private var header: some View {
        HStack {
            if case .params(let type, _) = stage {
                Button {
                    stage = .list
                } label: {
                    Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(MagicColor.textSecondary)
                Text(type.title.replacingOccurrences(of: "…", with: ""))
                    .font(MagicFont.display(17))
                    .foregroundStyle(MagicColor.textPrimary)
            } else {
                Text(title)
                    .font(MagicFont.display(17))
                    .foregroundStyle(MagicColor.textPrimary)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(MagicColor.textSecondary)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 12)
    }

    // MARK: List

    private var actionList: some View {
        ScrollView {
            VStack(spacing: 2) {
                if current != nil {
                    row(icon: "minus.circle", name: "Remove action", hint: "") { onSet(nil) }
                }
                ForEach(ActionType.allCases) { type in
                    row(icon: type.icon, name: type.title, hint: "") {
                        stage = .params(type, type.makeEmpty())
                    }
                }
                ForEach(MediaCommand.allCases, id: \.self) { command in
                    row(icon: command.icon, name: command.label, hint: "") {
                        onSet(.media(command: command))
                    }
                }
            }
        }
        .frame(maxHeight: 236)
    }

    private func row(icon: String, name: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(MagicColor.surfaceSunken)
                        .frame(width: 28, height: 28)
                    Image(systemName: icon).font(.system(size: 15, weight: .medium))
                        .foregroundStyle(MagicColor.textPrimary)
                }
                Text(name).font(MagicFont.text(15)).foregroundStyle(MagicColor.textPrimary)
                Spacer(minLength: 8)
                if !hint.isEmpty {
                    Text(hint).font(MagicFont.text(12, weight: .medium)).foregroundStyle(MagicColor.textSecondary)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(HoverHighlight())
    }

    // MARK: Param form

    @ViewBuilder
    private func paramForm(_ type: ActionType, _ draft: ActionConfig) -> some View {
        ParamForm(type: type, initial: draft) { configured in
            onSet(configured)
        }
    }
}

/// A subtle hover background for list rows.
private struct HoverHighlight: View {
    @State private var hover = false
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(hover ? MagicColor.surfacePageAlt : Color.clear)
            .onHover { hover = $0 }
    }
}

/// Parameter entry for a parameterised action type, with a Set button.
private struct ParamForm: View {
    let type: ActionType
    let initial: ActionConfig
    let onSet: (ActionConfig) -> Void

    @State private var bundleID = ""
    @State private var urlString = ""
    @State private var script = ""
    @State private var keyCode: UInt16 = 0
    @State private var modifiers: [KeyModifier] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            fields
            HStack {
                Spacer()
                Button("Set") { onSet(build()) }
                    .buttonStyle(.borderedProminent)
                    .tint(MagicColor.cerulean)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
        .onAppear(perform: seed)
    }

    @ViewBuilder
    private var fields: some View {
        switch type {
        case .openApp:
            HStack(spacing: 8) {
                TextField("com.apple.Music", text: $bundleID).textFieldStyle(.roundedBorder)
                Button("Choose…") { chooseApp() }
            }
        case .openURL:
            TextField("https://usemagic.io", text: $urlString).textFieldStyle(.roundedBorder)
        case .keystroke:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Key code").font(MagicFont.text(13)).foregroundStyle(MagicColor.textSecondary)
                    TextField("0", value: $keyCode, format: .number)
                        .textFieldStyle(.roundedBorder).frame(width: 70)
                }
                HStack(spacing: 8) {
                    ForEach(KeyModifier.allCases, id: \.self) { modifier in
                        Toggle(modifier.symbol, isOn: Binding(
                            get: { modifiers.contains(modifier) },
                            set: { on in
                                modifiers.removeAll { $0 == modifier }
                                if on { modifiers.append(modifier) }
                            }))
                            .toggleStyle(.button)
                    }
                }
            }
        case .shellScript:
            TextField("say hello", text: $script)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
    }

    private func seed() {
        switch initial {
        case .openApp(let b): bundleID = b
        case .openURL(let u): urlString = u
        case .keystroke(let c, let m): keyCode = c; modifiers = m
        case .shellScript(let s): script = s
        case .media: break
        }
    }

    private func build() -> ActionConfig {
        switch type {
        case .openApp: return .openApp(bundleID: bundleID)
        case .openURL: return .openURL(urlString: urlString)
        case .keystroke: return .keystroke(keyCode: keyCode, modifiers: modifiers)
        case .shellScript: return .shellScript(script: script)
        }
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url,
           let bundle = Bundle(url: url), let id = bundle.bundleIdentifier {
            bundleID = id
        }
    }
}
