import AppKit
import SwiftUI
import MagicKeysCore
import ServiceManagement

/// The dropdown panel shown when the menu-bar icon is clicked. Matches the
/// Claude Design "Magic Keys Popover": header, per-app profile chips, the
/// keycap device + gesture rows, an action picker, and a footer.
struct MenuBarPanel: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedKey = 0
    @State private var picking: Slot?

    enum Slot: Equatable {
        case tap, doubleTap, hold
        var label: String {
            switch self {
            case .tap: return "Tap"
            case .doubleTap: return "Double tap"
            case .hold: return "Hold"
            }
        }
    }

    private var config: K1Config { model.configStore.config }
    private var profile: AppProfile { model.editingProfile }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(MagicColor.borderDefault).padding(.vertical, 12)
            appsSection
            // Card and picker share a fixed-height region and swap in place, so
            // the menu-bar popover never has to grow (it can't resize once open).
            ZStack {
                if let slot = picking {
                    ActionPickerSheet(
                        title: "Assign to \(slot.label.lowercased())",
                        current: action(slot),
                        onSet: { setAction(slot, $0); picking = nil },
                        onClose: { picking = nil })
                        .transition(.opacity)
                } else {
                    mainCard
                        .frame(maxHeight: .infinity, alignment: .top)
                        .transition(.opacity)
                }
            }
            .frame(height: 290)
            .padding(.top, 14)
            footer.padding(.top, 14)
        }
        .padding(16)
        .frame(width: 470)
        .background(MagicColor.surfaceGlass)
        .onAppear {
            DispatchQueue.main.async { NSApp.activate(ignoringOtherApps: true) }
        }
        .animation(.easeOut(duration: 0.18), value: picking)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Magic Keys")
                    .font(MagicFont.display(30))
                    .foregroundStyle(MagicColor.textPrimary)
                HStack(spacing: 6) {
                    Circle()
                        .fill(model.isConnected ? MagicColor.stateSuccess : MagicColor.slate300)
                        .frame(width: 8, height: 8)
                    Text(statusLine)
                        .font(MagicFont.text(12, weight: .medium))
                        .kerning(1.0)
                        .textCase(.uppercase)
                        .foregroundStyle(MagicColor.textSecondary)
                }
            }
            Spacer()
        }
    }

    private var statusLine: String {
        guard model.isConnected else { return "K1 · not connected" }
        if let info = model.deviceInfo {
            return "K1 · fw \(info.firmwareMajor).\(info.firmwareMinor)"
        }
        return "K1 · USB-C"
    }

    // MARK: Apps section

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Applications")
                    .font(MagicFont.text(12, weight: .medium))
                    .kerning(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(MagicColor.textSecondary)
                Spacer()
                addAppMenu
            }
            Text("Give an app its own key setup — otherwise keys use your defaults.")
                .font(MagicFont.text(12))
                .foregroundStyle(MagicColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            AppChipsView(profiles: config.profiles,
                         selectedID: model.editingProfileID,
                         onSelect: { model.selectProfile(id: $0); picking = nil },
                         edgeInset: 16)
        }
    }

    private var addAppMenu: some View {
        let apps = model.addableApps()
        return Menu {
            if apps.isEmpty {
                Text("No other apps running")
            } else {
                ForEach(apps) { app in
                    Button {
                        model.addProfile(bundleID: app.id, name: app.name)
                    } label: {
                        if let icon = ProfileIcon.appIcon(app.id) {
                            Label { Text(app.name) } icon: { Image(nsImage: icon) }
                        } else {
                            Text(app.name)
                        }
                    }
                }
            }
            Divider()
            Button("Choose from Applications…") { model.addProfileByChoosingApp() }
        } label: {
            Image(systemName: "plus").font(.system(size: 14, weight: .semibold))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .foregroundStyle(MagicColor.cerulean)
        .help("Add an app profile")
    }

    // MARK: Main card

    private var mainCard: some View {
        HStack(alignment: .top, spacing: 18) {
            KeycapDeviceView(selectedKey: $selectedKey, boundCounts: boundCounts)
                .padding(.leading, 6)
                .padding(.top, 4)
            gesturesColumn
                .id(model.editingProfileID)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.2), value: model.editingProfileID)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(MagicColor.surfaceCard)
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(MagicColor.borderSubtle, lineWidth: 1))
                .shadow(color: MagicColor.prussian.opacity(0.06), radius: 2, y: 1)
        )
    }

    private var gesturesColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Key \(selectedKey + 1) gestures")
                    .font(MagicFont.text(12, weight: .medium))
                    .kerning(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(MagicColor.textSecondary)
                Spacer()
                Text(profile.isDefault ? "All apps" : profile.name)
                    .font(MagicFont.text(12))
                    .foregroundStyle(MagicColor.textSecondary)
            }
            VStack(spacing: 8) {
                gestureRow(.tap)
                gestureRow(.doubleTap)
                gestureRow(.hold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func gestureRow(_ slot: Slot) -> some View {
        GestureRow(label: slot.label,
                   action: action(slot),
                   inherited: config.inheritedAction(for: gesture(slot), profileID: model.editingProfileID),
                   isOpen: picking == slot,
                   onTap: { picking = (picking == slot) ? nil : slot })
    }

    private func gesture(_ slot: Slot) -> MagicKeysCore.Gesture {
        switch slot {
        case .tap: return .tap(key: selectedKey)
        case .doubleTap: return .doubleTap(key: selectedKey)
        case .hold: return .hold(key: selectedKey)
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 14) {
            Text(model.isConnected
                 ? "Firmware \(model.deviceInfo.map { "\($0.firmwareMajor).\($0.firmwareMinor)" } ?? "—") · Connected"
                 : "Not connected · plug in your K1")
                .font(MagicFont.text(12))
                .foregroundStyle(MagicColor.textSecondary)
                .lineLimit(1)
            Spacer(minLength: 8)
            #if DEBUG
            Menu {
                ForEach(0..<3, id: \.self) { key in
                    Button("Key \(key + 1): tap") { model.simulatePress(key: key) }
                    Button("Key \(key + 1): double tap") {
                        model.simulatePress(key: key)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { model.simulatePress(key: key) }
                    }
                    Button("Key \(key + 1): hold") { model.simulatePress(key: key, duration: 0.6) }
                }
            } label: {
                Image(systemName: "wand.and.stars").font(.system(size: 12))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .foregroundStyle(MagicColor.textTertiary)
            .help("Virtual K1 (debug)")
            #endif
            Toggle(isOn: launchAtLogin) {
                Text("Launch at Login").font(MagicFont.text(12, weight: .medium))
            }
            .toggleStyle(.checkbox)
            .foregroundStyle(MagicColor.textPrimary)
            .fixedSize()
            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
                    .font(MagicFont.text(13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(MagicColor.textPrimary)
        }
        .padding(.horizontal, 2)
    }

    private var launchAtLogin: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { enable in
                do {
                    if enable { try SMAppService.mainApp.register() }
                    else { try SMAppService.mainApp.unregister() }
                } catch { NSLog("MagicKeys: launch-at-login failed: \(error)") }
            })
    }

    // MARK: Binding helpers

    private var boundCounts: [Int] {
        profile.keys.map { [$0.tap, $0.doubleTap, $0.hold].compactMap { $0 }.count }
    }

    private func action(_ slot: Slot) -> ActionConfig? {
        guard profile.keys.indices.contains(selectedKey) else { return nil }
        let binding = profile.keys[selectedKey]
        switch slot {
        case .tap: return binding.tap
        case .doubleTap: return binding.doubleTap
        case .hold: return binding.hold
        }
    }

    private func setAction(_ slot: Slot, _ value: ActionConfig?) {
        model.configStore.update { config in
            guard let pi = config.profileIndex(id: model.editingProfileID),
                  config.profiles[pi].keys.indices.contains(selectedKey) else { return }
            switch slot {
            case .tap: config.profiles[pi].keys[selectedKey].tap = value
            case .doubleTap: config.profiles[pi].keys[selectedKey].doubleTap = value
            case .hold: config.profiles[pi].keys[selectedKey].hold = value
            }
        }
    }
}
