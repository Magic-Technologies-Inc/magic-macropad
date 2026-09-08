import SwiftUI
import MagicKeysCore

struct ConfigView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedKey = 0

    var body: some View {
        HSplitView {
            devicePane
                .frame(minWidth: 180, maxWidth: 220, maxHeight: .infinity)
            bindingsPane
                .frame(minWidth: 340, maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 560, minHeight: 380)
    }

    private var devicePane: some View {
        VStack(spacing: 16) {
            Text(model.isConnected ? "K1 connected" : "K1 not connected")
                .font(.subheadline)
                .foregroundStyle(model.isConnected ? .primary : .secondary)
            // Stylized device: three keys in a vertical strip, like the
            // K1 sitting along the MacBook edge.
            VStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { key in
                    Button {
                        selectedKey = key
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedKey == key ? Color.accentColor.opacity(0.35)
                                                     : Color(nsColor: .controlBackgroundColor))
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(selectedKey == key ? Color.accentColor : .secondary.opacity(0.4)))
                            .overlay(Text("\(key + 1)").font(.title2.bold()))
                            .frame(width: 64, height: 64)
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
        .padding()
    }

    private var bindingsPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Key \(selectedKey + 1)").font(.title2.bold())
                ActionPickerView(title: "Tap", action: binding(\.tap))
                ActionPickerView(title: "Double Tap", action: binding(\.doubleTap))
                ActionPickerView(title: "Hold", action: binding(\.hold))
            }
            .padding()
        }
    }

    private func binding(_ keyPath: WritableKeyPath<KeyBinding, ActionConfig?>) -> Binding<ActionConfig?> {
        Binding(
            get: { model.configStore.config.keys[selectedKey][keyPath: keyPath] },
            set: { newValue in
                model.configStore.update { $0.keys[selectedKey][keyPath: keyPath] = newValue }
            })
    }
}
