import AppKit
import SwiftUI
import MagicKeysCore

/// Horizontal row of per-app profile chips — each shows its icon + name at a
/// fixed size; only the selected chip's styling changes, so nothing reflows.
struct AppChipsView: View {
    let profiles: [AppProfile]
    let selectedID: String
    let onSelect: (String) -> Void
    /// The parent's horizontal content margin — the row breaks out past it so
    /// chips scroll all the way to the panel edge, while resting aligned.
    var edgeInset: CGFloat = 0

    // Click-drag panning fallback (mice with no horizontal wheel / no trackpad).
    @State private var anchorIndex = 0
    @State private var dragBaseIndex: Int?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(profiles) { profile in
                        chip(profile).id(profile.id)
                    }
                }
                .padding(.horizontal, edgeInset)
                .padding(.vertical, 1)
                .frame(height: 42)
            }
            .frame(height: 42)
            .padding(.horizontal, -edgeInset)
            // Native wheel/trackpad still scroll; this adds mouse click-drag panning.
            .simultaneousGesture(dragToScroll(proxy))
        }
    }

    private func dragToScroll(_ proxy: ScrollViewProxy) -> some SwiftUI.Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard profiles.count > 1 else { return }
                let base = dragBaseIndex ?? anchorIndex
                dragBaseIndex = base
                let stride: CGFloat = 108  // approx chip width + spacing
                let steps = Int((-value.translation.width / stride).rounded())
                let target = min(max(0, base + steps), profiles.count - 1)
                if target != anchorIndex {
                    anchorIndex = target
                    withAnimation(.easeOut(duration: 0.14)) {
                        proxy.scrollTo(profiles[target].id, anchor: .leading)
                    }
                }
            }
            .onEnded { _ in dragBaseIndex = nil }
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
                    .overlay(Capsule().strokeBorder(active ? MagicColor.cerulean.opacity(0.55)
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
