import AppKit
import SwiftUI
import MagicKeysCore

/// Horizontal row of per-app profile chips. The active profile expands to show
/// its name; the rest are icon-only circles.
struct AppChipsView: View {
    let profiles: [AppProfile]
    let selectedID: String
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(profiles) { profile in
                    chip(profile)
                }
            }
            .padding(.vertical, 1)
            .frame(height: 42)
            .animation(.easeInOut(duration: 0.16), value: selectedID)
        }
        .frame(height: 42)
    }

    @ViewBuilder
    private func chip(_ profile: AppProfile) -> some View {
        let active = profile.id == selectedID
        Button {
            onSelect(profile.id)
        } label: {
            HStack(spacing: 8) {
                ProfileIcon(profile: profile, size: 18)
                if active {
                    Text(profile.name)
                        .font(MagicFont.text(14, weight: .medium))
                        .foregroundStyle(MagicColor.textPrimary)
                        .fixedSize()
                        .transition(.opacity)
                }
            }
            .frame(height: 40)
            .padding(.horizontal, active ? 14 : 0)
            .frame(minWidth: active ? nil : 40)
            .background {
                ZStack {
                    Circle().fill(MagicColor.surfacePage.opacity(0.5)).opacity(active ? 0 : 1)
                    Capsule().fill(MagicColor.surfaceCard)
                        .overlay(Capsule().strokeBorder(MagicColor.borderSubtle, lineWidth: 1))
                        .shadow(color: MagicColor.prussian.opacity(0.10), radius: 2, y: 1)
                        .opacity(active ? 1 : 0)
                }
            }
            .foregroundStyle(active ? MagicColor.textPrimary : MagicColor.textSecondary)
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
