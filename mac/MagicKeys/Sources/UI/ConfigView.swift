import SwiftUI
import MagicKeysCore

struct ConfigView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedKey = 0

    var body: some View {
        HStack(spacing: 0) {
            devicePane
                .frame(width: 400)
                .frame(maxHeight: .infinity)
            bindingsPane
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(MagicColor.surfacePage)
        }
        .frame(minWidth: 940, maxWidth: 1100, minHeight: 620, maxHeight: 760)
    }

    // MARK: Left — the device on its backdrop

    private var devicePane: some View {
        ZStack {
            MagicColor.deviceBackdrop
            RadialGradient(
                colors: [MagicColor.sky.opacity(0.18), .clear],
                center: .init(x: 0.5, y: 0.42), startRadius: 40, endRadius: 340)

            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("K1")
                        .font(MagicFont.display(40, bold: true))
                        .foregroundStyle(MagicColor.textPrimary)
                    Text("Magic Keys")
                        .font(MagicFont.text(13, weight: .medium))
                        .foregroundStyle(MagicColor.textSecondary)
                }
                DeviceView(selectedKey: $selectedKey)
                statusPill
            }
            .padding(.vertical, 36)
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(model.isConnected ? Color(hex: 0x2FA463) : MagicColor.slate300)
                .frame(width: 8, height: 8)
            Text(model.isConnected
                 ? "Connected" + (model.deviceInfo.map { " · fw \($0.firmwareMajor).\($0.firmwareMinor)" } ?? "")
                 : "Not connected")
                .font(MagicFont.text(12, weight: .medium))
                .foregroundStyle(MagicColor.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(MagicColor.surfaceCard))
        .overlay(Capsule().strokeBorder(MagicColor.borderHairline, lineWidth: 1))
    }

    // MARK: Right — bindings for the selected key

    private var bindingsPane: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("KEY \(selectedKey + 1)")
                    .font(MagicFont.display(28, bold: true))
                    .foregroundStyle(MagicColor.textPrimary)
                Text("Choose what each gesture does.")
                    .font(MagicFont.text(13))
                    .foregroundStyle(MagicColor.textSecondary)
            }

            VStack(spacing: 12) {
                GestureCard(title: "Tap", gestureIcon: "hand.tap",
                            action: binding(\.tap))
                GestureCard(title: "Double Tap", gestureIcon: "hand.tap.fill",
                            action: binding(\.doubleTap))
                GestureCard(title: "Hold", gestureIcon: "hand.raised",
                            action: binding(\.hold))
            }

            Spacer()

            #if DEBUG
            if !model.isConnected {
                Text("No K1 attached — use the menu-bar icon's Virtual K1 to simulate presses.")
                    .font(MagicFont.text(11))
                    .foregroundStyle(MagicColor.textTertiary)
            }
            #endif
        }
        .padding(36)
    }

    private func binding(_ keyPath: WritableKeyPath<KeyBinding, ActionConfig?>) -> Binding<ActionConfig?> {
        Binding(
            get: { model.configStore.config.keys[selectedKey][keyPath: keyPath] },
            set: { newValue in
                model.configStore.update { $0.keys[selectedKey][keyPath: keyPath] = newValue }
            })
    }
}
