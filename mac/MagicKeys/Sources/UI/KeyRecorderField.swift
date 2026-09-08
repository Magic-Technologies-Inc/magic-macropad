import AppKit
import SwiftUI
import MagicKeysCore

/// A shortcut recorder: click to arm, then press a key combination and it
/// captures the key code + modifiers (Esc cancels). Mirrors the macOS
/// keyboard-shortcut recorder pattern.
struct KeyRecorderField: View {
    @Binding var keyCode: UInt16
    @Binding var modifiers: [KeyModifier]

    @State private var recording = false
    @State private var didRecord = false
    @State private var monitor: Any?

    private var hasValue: Bool { didRecord || !modifiers.isEmpty || keyCode != 0 }

    private var shortcutText: String {
        modifiers.map(\.symbol).joined() + KeyName.forCode(keyCode)
    }

    var body: some View {
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
                        keyCode = 0; modifiers = []; didRecord = false
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
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
            // Escape with no modifiers cancels.
            if event.keyCode == 53, mods.isEmpty {
                stop()
                return nil
            }
            keyCode = event.keyCode
            modifiers = Self.map(mods)
            didRecord = true
            stop()
            return nil  // swallow so it doesn't hit the app
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
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
