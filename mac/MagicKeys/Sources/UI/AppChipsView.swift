import AppKit
import SwiftUI
import MagicKeysCore

/// Horizontal row of per-app profile chips — each shows its icon + name at a
/// fixed size; only the selected chip's styling changes, so nothing reflows.
struct AppChipsView: View {
    let profiles: [AppProfile]
    let selectedID: String
    let onSelect: (String) -> Void
    /// Apps that can be added, plus the add callbacks — rendered as a trailing
    /// "+" capsule that scrolls with the chips.
    var addableApps: [AppModel.RunningApp] = []
    var onAddApp: (AppModel.RunningApp) -> Void = { _ in }
    var onChooseApp: () -> Void = {}
    /// The parent's horizontal content margin — the row breaks out past it so
    /// chips scroll all the way to the panel edge, while resting aligned.
    var edgeInset: CGFloat = 0

    var body: some View {
        // NSScrollView-backed: trackpad, mouse wheel (vertical → horizontal), and
        // click-drag panning all scroll the row.
        ChipsScroller(height: 42) {
            HStack(spacing: 8) {
                ForEach(profiles) { profile in
                    chip(profile)
                }
                addChip
            }
            .padding(.horizontal, edgeInset)
            .frame(height: 42)
        }
        .frame(height: 42)
        .padding(.horizontal, -edgeInset)
    }

    /// The trailing "+" capsule that opens the add-app menu, sized to match the
    /// chips so it sits in the same row and scrolls to the edge with them.
    private var addChip: some View {
        Menu {
            if addableApps.isEmpty {
                Text("No other apps running")
            } else {
                ForEach(addableApps) { app in
                    Button {
                        onAddApp(app)
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
            Button("Choose from Applications…") { onChooseApp() }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 40, height: 40)
                .background(
                    Capsule()
                        .fill(MagicColor.surfacePageAlt.opacity(0.6))
                        .overlay(Capsule().strokeBorder(MagicColor.borderSubtle, lineWidth: 1))
                )
                .foregroundStyle(MagicColor.accentBlue)
                .contentShape(Capsule())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Add an app profile")
    }

    private func chip(_ profile: AppProfile) -> some View {
        let active = profile.id == selectedID
        return Button {
            onSelect(profile.id)
        } label: {
            HStack(spacing: 8) {
                ProfileIcon(profile: profile, size: 18)
                Text(profile.name)
                    .font(MagicFont.text(14, weight: .medium))  // constant weight → width never changes
                    .fixedSize()
            }
            .frame(height: 40)
            .padding(.horizontal, 14)
            .background(
                Capsule()
                    .fill(active ? MagicColor.surfaceCard : MagicColor.surfacePageAlt.opacity(0.6))
                    .overlay(Capsule().strokeBorder(active ? MagicColor.accentBlue.opacity(0.7)
                                                    : MagicColor.borderSubtle,
                                                    lineWidth: active ? 1.5 : 1))
                    .shadow(color: active ? MagicColor.prussian.opacity(0.12) : .clear, radius: 3, y: 1)
            )
            .foregroundStyle(active ? MagicColor.textPrimary : MagicColor.textSecondary)
            // Color/selection crossfades in place; width never changes, so
            // neighbouring chips don't shift.
            .animation(.easeInOut(duration: 0.15), value: active)
        }
        .buttonStyle(.plain)
        .help(profile.name)
    }
}

/// A profile's icon: the real app icon when available, else its SF Symbol.
struct ProfileIcon: View {
    let profile: AppProfile
    var size: CGFloat

    var body: some View {
        if let bundleID = profile.bundleID, let nsImage = Self.appIcon(bundleID) {
            Image(nsImage: nsImage)
                .resizable()
                .frame(width: size + 2, height: size + 2)
                .clipShape(RoundedRectangle(cornerRadius: (size + 2) * 0.22, style: .continuous))
        } else {
            Image(systemName: profile.symbol)
                .font(.system(size: size * 0.85, weight: .medium))
        }
    }

    static func appIcon(_ bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}
