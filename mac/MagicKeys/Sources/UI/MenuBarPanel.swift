import AppKit
import SwiftUI
import MagicKeysCore
import ServiceManagement

/// The dropdown panel shown when the menu-bar icon is clicked: the full
/// Magic Keys config surface plus a slim footer of app controls.
struct MenuBarPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            ConfigView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            footer
        }
        .frame(width: 820, height: 560)
        .background(MagicColor.surfacePage)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            #if DEBUG
            Menu {
                ForEach(0..<3, id: \.self) { key in
                    Menu("Key \(key + 1)") {
                        Button("Tap") { model.simulatePress(key: key) }
                        Button("Double Tap") {
                            model.simulatePress(key: key)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                model.simulatePress(key: key)
                            }
                        }
                        Button("Hold") { model.simulatePress(key: key, duration: 0.6) }
                    }
                }
            } label: {
                Label("Virtual K1", systemImage: "wand.and.stars")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            #endif

            Spacer()

            Toggle("Launch at Login", isOn: Binding(
                get: { SMAppService.mainApp.status == .enabled },
                set: { enable in
                    do {
                        if enable { try SMAppService.mainApp.register() }
                        else { try SMAppService.mainApp.unregister() }
                    } catch {
                        NSLog("MagicKeys: launch-at-login failed: \(error)")
                    }
                }))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .font(MagicFont.text(12))
                .foregroundStyle(MagicColor.textSecondary)

            Button {
                NSApp.terminate(nil)
            } label: {
                Text("Quit")
                    .font(MagicFont.text(12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(MagicColor.textSecondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(MagicColor.surfaceCard)
    }
}
