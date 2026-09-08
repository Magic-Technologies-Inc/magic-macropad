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
            case .params(let type, let draft):
                paramForm(type, draft)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        .frame(maxHeight: .infinity)
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
            if type != .openApp {  // Open App commits on selection — no Set button.
                HStack {
                    Spacer()
                    Button("Set") { onSet(build()) }
                        .buttonStyle(.borderedProminent)
                        .tint(MagicColor.cerulean)
                }
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
            appPicker
        case .openURL:
            TextField("https://usemagic.io", text: $urlString).textFieldStyle(.roundedBorder)
        case .keystroke:
            KeyRecorderField(keyCode: $keyCode, modifiers: $modifiers)
        case .shellScript:
            TextField("say hello", text: $script)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
    }

    /// Pick an app from a menu of running apps (or browse Applications) — no typing.
    private var appPicker: some View {
        Menu {
            ForEach(runningApps(), id: \.id) { app in
                Button {
                    onSet(.openApp(bundleID: app.id))
                } label: {
                    if let icon = ProfileIcon.appIcon(app.id) {
                        Label { Text(app.name) } icon: { Image(nsImage: icon) }
                    } else {
                        Text(app.name)
                    }
                }
            }
            Divider()
            Button("Choose from Applications…") { chooseApp() }
        } label: {
            HStack(spacing: 8) {
                if bundleID.isEmpty {
                    Image(systemName: "app.dashed").foregroundStyle(MagicColor.textSecondary)
                    Text("Choose an app…").foregroundStyle(MagicColor.textSecondary)
                } else {
                    if let icon = ProfileIcon.appIcon(bundleID) {
                        Image(nsImage: icon).resizable().frame(width: 18, height: 18)
                    }
                    Text(appName(bundleID)).foregroundStyle(MagicColor.textPrimary)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11)).foregroundStyle(MagicColor.textTertiary)
            }
            .font(MagicFont.text(14))
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(RoundedRectangle(cornerRadius: 8).fill(MagicColor.surfacePageAlt)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(MagicColor.borderDefault, lineWidth: 1)))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private func runningApps() -> [(id: String, name: String)] {
        var seen = Set<String>()
        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> (id: String, name: String)? in
                guard let id = app.bundleIdentifier, seen.insert(id).inserted,
                      let name = app.localizedName else { return nil }
                return (id, name)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func appName(_ bundleID: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return bundleID }
        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
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
            onSet(.openApp(bundleID: id))
        }
    }
}
