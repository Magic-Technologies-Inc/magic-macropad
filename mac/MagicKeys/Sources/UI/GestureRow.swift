import SwiftUI
import MagicKeysCore

/// A single gesture slot row (Tap / Double tap / Hold) in the design's list style.
struct GestureRow: View {
    let label: String
    let action: ActionConfig?
    let isOpen: Bool
    let onTap: () -> Void
    @State private var isHovered = false

    private var assigned: Bool { action != nil }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                iconSquare
                VStack(alignment: .leading, spacing: 2) {
                    Text(label.uppercased())
                        .font(MagicFont.text(10, weight: .medium))
                        .kerning(1.3)
                        .foregroundStyle(MagicColor.textSecondary)
                    Text(action?.name ?? "Not assigned")
                        .font(MagicFont.text(15))
                        .foregroundStyle(assigned ? MagicColor.textPrimary : MagicColor.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer(minLength: 8)
                if let hint = action?.shortcutHint, !hint.isEmpty {
                    Text(hint)
                        .font(MagicFont.text(11, weight: .medium))
                        .foregroundStyle(MagicColor.textSecondary)
                        .fixedSize()
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MagicColor.textSecondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 58)
            .contentShape(Rectangle())
            .background(background)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isOpen)
    }

    private var iconSquare: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(MagicColor.surfaceSunken)
                .frame(width: 30, height: 30)
            Image(systemName: action?.icon ?? "plus")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MagicColor.textPrimary)
        }
    }

    private var background: some View {
        let fill = isOpen ? MagicColor.surfaceAccentSoft
            : (isHovered ? MagicColor.surfaceSunken : MagicColor.surfacePageAlt)
        let stroke = isOpen ? MagicColor.borderAccent : MagicColor.borderSubtle
        return RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(fill)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(stroke, lineWidth: 1))
    }
}
