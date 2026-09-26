import AppKit
import SwiftUI
import MagicKeysCore

/// A shortcut recorder: click to arm, then press a key combination and it
/// captures the key code + modifiers (Esc cancels). Mirrors the macOS
/// keyboard-shortcut recorder pattern.
///
/// System combos like ⌘Tab can't be captured — the WindowServer consumes them
/// before the keyDown reaches the app. We detect that case (the app resigns
/// active while a modifier is held) and point the user at the System Action.
struct KeyRecorderField: View {
    @Binding var keyCode: UInt16?  // nil until a key is recorded
    @Binding var modifiers: [KeyModifier]

    @State private var recording = false
    @State private var warning: String?
    @State private var monitor: Any?
    @State private var flagsMonitor: Any?
    @State private var resignObserver: NSObjectProtocol?
    // Reference-typed so the escaping monitors/observer read live values rather
    // than a stale copy of this (value-type) view.
    @State private var live = LiveState()

    private final class LiveState {
        var active = false          // recording in progress
        var modifiersHeld = false   // a modifier is currently down
    }

    private var hasValue: Bool { keyCode != nil }

    private var shortcutText: String {
        modifiers.map(\.symbol).joined() + (keyCode.map(KeyName.forCode) ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: toggle) {
                HStack(spacing: 8) {
                    Image(systemName: recording ? "record.circle.fill" : "keyboard")
                        .foregroundStyle(recording ? MagicColor.dawn : MagicColor.textSecondary)
                    Text(label)
                        .font(recording ? MagicFont.text(13) : MagicFont.text(14, weight: hasValue ? .semibold : .regular))
                        .foregroundStyle(recording ? MagicColor.textSecondary
                                         : (hasValue ? MagicColor.textPrimary : MagicColor.textSecondary))
                    Spacer(minLength: 8)
                    if hasValue && !recording {
                        Button {
                            keyCode = nil; modifiers = []
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(MagicColor.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 34)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(MagicColor.surfacePageAlt)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(recording ? MagicColor.borderAccent : MagicColor.borderDefault,
                                          lineWidth: recording ? 2 : 1))
                )
            }
            .buttonStyle(.plain)

            if let warning {
                Text(warning)
                    .font(MagicFont.text(12))
                    .foregroundStyle(MagicColor.dawn)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onDisappear(perform: stop)
    }

    private var label: String {
        if recording { return "Press keys… (⎋ to cancel)" }
        return hasValue ? shortcutText : "Click to record shortcut"
    }

    private func toggle() {
        recording ? stop() : start()
    }

    private func start() {
        recording = true
        warning = nil
        live.active = true
        live.modifiersHeld = false

        // Track modifier state while we're still frontmost (delivered before a
        // system shortcut steals focus).
        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { event in
            live.modifiersHeld = !event.modifierFlags
                .intersection([.command, .shift, .option, .control]).isEmpty
            return event
        }

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
            // Escape with no modifiers cancels.
            if event.keyCode == 53, mods.isEmpty {
                stop()
                return nil
            }
            keyCode = event.keyCode
            modifiers = Self.map(mods)
            warning = nil
            stop()
            return nil  // swallow so it doesn't hit the app
        }

        // If the app resigns active mid-recording while a modifier is held, a
        // reserved system shortcut (⌘Tab, Spotlight, Mission Control…) ate it.
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { _ in
            guard live.active else { return }
            if live.modifiersHeld {
                warning = "That shortcut is reserved by macOS (like ⌘Tab) and can't be recorded — pick a System Action instead."
            }
            stop()
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
        if let flagsMonitor { NSEvent.removeMonitor(flagsMonitor); self.flagsMonitor = nil }
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver); self.resignObserver = nil }
        live.active = false
        recording = false
    }

    private static func map(_ flags: NSEvent.ModifierFlags) -> [KeyModifier] {
        var result: [KeyModifier] = []
        if flags.contains(.control) { result.append(.control) }
        if flags.contains(.option) { result.append(.option) }
        if flags.contains(.shift) { result.append(.shift) }
        if flags.contains(.command) { result.append(.command) }
        return result
    }
}
