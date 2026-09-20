import AppKit
import SwiftUI
import UniformTypeIdentifiers
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
    @State private var stage: Stage

    init(title: String, current: ActionConfig?,
         onSet: @escaping (ActionConfig?) -> Void, onClose: @escaping () -> Void) {
        self.title = title
        self.current = current
        self.onSet = onSet
        self.onClose = onClose
        // If the gesture already has an action, open straight into its editor.
        _stage = State(initialValue: Self.initialStage(for: current))
    }

    private static func initialStage(for current: ActionConfig?) -> Stage {
        switch current {
        case .openApp: return .params(.openApp, current!)
        case .openURL: return .params(.openURL, current!)
        case .openPath: return .params(.openFile, current!)
        case .keystroke: return .params(.keystroke, current!)
        case .pasteText: return .params(.pasteText, current!)
        case .shellScript: return .params(.shellScript, current!)
        case .media, .system, .ai, .none: return .list  // ready-made → show the list
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            switch stage {
            case .list: actionList
            case .params(let type, let draft):
                paramForm(type, draft)
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
        HStack(spacing: 8) {
            Button(action: onClose) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                    Text("Back").font(MagicFont.text(13, weight: .medium))
                }
                .frame(height: 30)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(MagicColor.accentBlue)

            Spacer()
            Text(headerTitle)
                .font(MagicFont.display(16))
                .foregroundStyle(MagicColor.textPrimary)
            Spacer()

            if case .params = stage {
                Button { stage = .list } label: {
                    Text("Change action")
                        .font(MagicFont.text(13, weight: .medium))
                        .frame(height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(MagicColor.accentBlue)
            } else {
                // Balance the title so it stays centered.
                Text("Back").font(MagicFont.text(13, weight: .medium)).opacity(0)
            }
        }
        .padding(.bottom, 10)
    }

    private var headerTitle: String {
        if case .params(let type, _) = stage {
            return type.title.replacingOccurrences(of: "…", with: "")
        }
        return title
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
                ForEach(SystemCommand.allCases, id: \.self) { command in
                    row(icon: command.icon, name: command.label, hint: "") {
                        onSet(.system(command: command))
                    }
                }
                ForEach(AICommand.allCases, id: \.self) { command in
                    row(icon: command.icon, name: command.label, hint: "") {
                        onSet(.ai(command: command))
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

    private func paramForm(_ type: ActionType, _ draft: ActionConfig) -> some View {
        ParamForm(type: type, initial: draft, onSet: { onSet($0) })
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
    @State private var path = ""
    @State private var script = ""
    @State private var name = ""
    @State private var text = ""
    @State private var keyCode: UInt16 = 0
    @State private var modifiers: [KeyModifier] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            fields
            buttonRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 4)
        .padding(.top, 2)
        .onAppear(perform: seed)
    }

    @ViewBuilder
    private var buttonRow: some View {
        HStack(spacing: 8) {
            if type == .shellScript {
                Menu {
                    ForEach(ScriptPresets.all) { preset in
                        Button(preset.name) {
                            script = preset.script
                            if name.isEmpty { name = preset.name }
                        }
                    }
                } label: {
                    Label("Examples", systemImage: "sparkles")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                Button { loadShellFile() } label: {
                    Label("Load .sh file…", systemImage: "doc.text")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            Spacer()
            // Open App and Open File commit on selection — no Set button.
            if type != .openApp && type != .openFile {
                Button("Set") { onSet(build()) }
                    .buttonStyle(.borderedProminent)
                    .tint(MagicColor.cerulean)
            }
        }
    }

    @ViewBuilder
    private var fields: some View {
        switch type {
        case .openApp:
            appPicker
        case .openURL:
            TextField("https://usemagic.io", text: $urlString).textFieldStyle(.roundedBorder)
        case .openFile:
            filePicker
        case .keystroke:
            KeyRecorderField(keyCode: $keyCode, modifiers: $modifiers)
        case .pasteText:
            ScriptEditor(text: $text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(MagicColor.surfacePageAlt)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(MagicColor.borderDefault, lineWidth: 1)))
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Text to paste — a snippet, email, address, template…")
                            .font(.system(size: 13))
                            .foregroundStyle(MagicColor.textTertiary)
                            .padding(.leading, 10)
                            .padding(.top, 10)
                            .allowsHitTesting(false)
                    }
                }
        case .shellScript:
            VStack(alignment: .leading, spacing: 8) {
                TextField("Name (optional) — e.g. Save & Push", text: $name)
                    .textFieldStyle(.roundedBorder)
                ScriptEditor(text: $script)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(MagicColor.surfacePageAlt)
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(MagicColor.borderDefault, lineWidth: 1)))
                    .overlay(alignment: .topLeading) {
                        if script.isEmpty {
                            // ScriptEditor's text starts at inset (10, 10) — match it exactly.
                            Text("Paste your script here, or pick an example…")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(MagicColor.textTertiary)
                                .padding(.leading, 10)
                                .padding(.top, 10)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
    }

    /// Pick a file or folder; commits immediately on choosing (like the app picker).
    private var filePicker: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder").foregroundStyle(MagicColor.textSecondary)
            Text(path.isEmpty ? "Choose a file or folder…" : (path as NSString).lastPathComponent)
                .foregroundStyle(path.isEmpty ? MagicColor.textSecondary : MagicColor.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 8)
            Button("Choose…") { chooseFileOrFolder() }
                .controlSize(.small)
        }
        .font(MagicFont.text(14))
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(RoundedRectangle(cornerRadius: 8).fill(MagicColor.surfacePageAlt)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(MagicColor.borderDefault, lineWidth: 1)))
    }

    private func chooseFileOrFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            path = url.path
            onSet(.openPath(path: url.path))
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
        case .openPath(let p): path = p
        case .keystroke(let c, let m): keyCode = c; modifiers = m
        case .pasteText(let t): text = t
        case .shellScript(let s, let n): script = s; name = n ?? ""
        case .media, .system, .ai: break
        }
    }

    private func build() -> ActionConfig {
        switch type {
        case .openApp: return .openApp(bundleID: bundleID)
        case .openURL: return .openURL(urlString: urlString)
        case .openFile: return .openPath(path: path)
        case .keystroke: return .keystroke(keyCode: keyCode, modifiers: modifiers)
        case .pasteText: return .pasteText(text: text)
        case .shellScript: return .shellScript(script: script, name: name.isEmpty ? nil : name)
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

    private func loadShellFile() {
        let panel = NSOpenPanel()
        var types: [UTType] = [.plainText, .text]
        if let sh = UTType(filenameExtension: "sh") { types.insert(sh, at: 0) }
        panel.allowedContentTypes = types
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url,
           let content = try? String(contentsOf: url, encoding: .utf8) {
            script = content
        }
    }
}

/// A monospaced, multi-line script editor with known text insets (10, 10) so a
/// placeholder can align exactly, and with smart substitutions off so scripts
/// aren't mangled by curly quotes/dashes.
private struct ScriptEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        guard let textView = scroll.documentView as? NSTextView else { return scroll }
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .labelColor
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.textContainer?.lineFragmentPadding = 0
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.allowsUndo = true
        textView.string = text
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let textView = scroll.documentView as? NSTextView, textView.string != text else { return }
        textView.string = text
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private let parent: ScriptEditor
        init(_ parent: ScriptEditor) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
