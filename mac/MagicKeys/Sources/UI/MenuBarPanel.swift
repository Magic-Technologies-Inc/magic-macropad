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
        case tap, doubleTap, tripleTap, hold
        var label: String {
            switch self {
            case .tap: return "Tap"
            case .doubleTap: return "Double tap"
            case .tripleTap: return "Triple tap"
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
            // Height matches the main card exactly (222pt holder + 4pt top inset
            // + 14pt card padding top & bottom) so no dead space sits below it;
            // the picker fills this region and scrolls.
            .frame(height: 254)
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
        HStack(alignment: .center) {
            Text("Magic Keys")
                .font(MagicFont.display(30))
                .foregroundStyle(MagicColor.textPrimary)
            Spacer()
            permissionsButton
        }
    }

    @State private var accessibilityTrusted = Permissions.isAccessibilityTrusted

    private var permissionsButton: some View {
        Button {
            Permissions.requestAll()
            // Re-check shortly after (the user grants in System Settings).
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                accessibilityTrusted = Permissions.isAccessibilityTrusted
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: accessibilityTrusted ? "checkmark.shield.fill" : "lock.shield")
                    .font(.system(size: 12, weight: .semibold))
                Text("Permissions")
                    .font(MagicFont.text(12, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(Capsule().fill(MagicColor.surfaceCard))
            .overlay(Capsule().strokeBorder(MagicColor.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .foregroundStyle(accessibilityTrusted ? MagicColor.stateSuccess : MagicColor.accentBlue)
        .help("Request Accessibility & Notification permissions (clears any stale grant from a previous build)")
        .onAppear { accessibilityTrusted = Permissions.isAccessibilityTrusted }
    }

    // MARK: Apps section

    private var appsSection: some View {
        HStack(alignment: .center, spacing: 8) {
            AppChipsView(profiles: config.profiles,
                         selectedID: model.editingProfileID,
                         onSelect: { model.selectProfile(id: $0); picking = nil },
                         edgeInset: 16)
            addAppMenu
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
        .foregroundStyle(MagicColor.accentBlue)
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
        VStack(spacing: 7) {
            gestureRow(.tap)
            gestureRow(.doubleTap)
            gestureRow(.tripleTap)
            gestureRow(.hold)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(MagicColor.surfaceAccentSoft)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(MagicColor.horizon.opacity(0.55), lineWidth: 1))
        )
        // A little tab pointing back at the selected keycap, so it's clear these
        // actions belong to the one highlighted key.
        .overlay(alignment: .topLeading) {
            LeftPointer()
                .fill(MagicColor.surfaceAccentSoft)
                .overlay(LeftPointer().stroke(MagicColor.horizon.opacity(0.55), lineWidth: 1))
                .frame(width: 9, height: 18)
                .offset(x: -8, y: connectorY - 9)
                .animation(.easeOut(duration: 0.16), value: selectedKey)
        }
        // Match the device holder's exact vertical extent (222pt tall, starting
        // at the same 4pt top inset) so the two boxes line up.
        .frame(height: KeycapDeviceView.holderHeight)
        .padding(.top, 4)
    }

    /// Vertical center of the selected keycap, relative to the panel box top.
    private var connectorY: CGFloat { 40 + CGFloat(selectedKey) * 71 }

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
        case .tripleTap: return .tripleTap(key: selectedKey)
        case .hold: return .hold(key: selectedKey)
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                Circle()
                    .fill(model.isConnected ? MagicColor.stateSuccess : MagicColor.slate300)
                    .frame(width: 8, height: 8)
                Text(model.isConnected ? "Connected" : "Not connected")
                    .font(MagicFont.text(12, weight: .medium))
                    .foregroundStyle(MagicColor.textSecondary)
            }
            Spacer(minLength: 8)
            #if DEBUG
            virtualK1Menu
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

    #if DEBUG
    private var virtualK1Menu: some View {
        Menu {
            ForEach(0..<3, id: \.self) { key in
                Menu("Key \(key + 1)") {
                    Button("Tap") { model.simulatePress(key: key) }
                    Button("Double tap") {
                        model.simulatePress(key: key)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { model.simulatePress(key: key) }
                    }
                    Button("Triple tap") {
                        model.simulatePress(key: key)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { model.simulatePress(key: key) }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { model.simulatePress(key: key) }
                    }
                    Button("Hold") { model.simulatePress(key: key, duration: 0.6) }
                }
            }
        } label: {
            Label("Test keys", systemImage: "wand.and.stars")
                .font(MagicFont.text(12, weight: .semibold))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .foregroundStyle(MagicColor.accentBlue)
        .help("Simulate key presses without hardware")
    }
    #endif

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
        profile.keys.map { [$0.tap, $0.doubleTap, $0.tripleTap, $0.hold].compactMap { $0 }.count }
    }

    private func action(_ slot: Slot) -> ActionConfig? {
        guard profile.keys.indices.contains(selectedKey) else { return nil }
        let binding = profile.keys[selectedKey]
        switch slot {
        case .tap: return binding.tap
        case .doubleTap: return binding.doubleTap
        case .tripleTap: return binding.tripleTap
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
            case .tripleTap: config.profiles[pi].keys[selectedKey].tripleTap = value
            case .hold: config.profiles[pi].keys[selectedKey].hold = value
            }
        }
    }
}

/// A small left-pointing triangle used as the connector tab from the gestures
/// panel back to the selected keycap.
private struct LeftPointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
