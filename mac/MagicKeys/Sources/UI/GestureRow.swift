import SwiftUI
import MagicKeysCore

/// A single gesture slot row (Tap / Double tap / Hold) in the design's list style.
struct GestureRow: View {
    let label: String
    let action: ActionConfig?
    /// When `action` is nil but the app profile inherits the default's binding.
    var inherited: ActionConfig? = nil
    let isOpen: Bool
    let onTap: () -> Void
    @State private var isHovered = false

    private var assigned: Bool { action != nil }
    /// The action actually shown: explicit if set, else the inherited default.
    private var shown: ActionConfig? { action ?? inherited }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                iconSquare
                VStack(alignment: .leading, spacing: 2) {
                    Text(label.uppercased())
                        .font(MagicFont.text(10, weight: .medium))
                        .kerning(1.3)
                        .foregroundStyle(MagicColor.textSecondary)
                    Text(shown?.name ?? "Not assigned")
                        .font(MagicFont.text(15))
                        .foregroundStyle(assigned ? MagicColor.textPrimary : MagicColor.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer(minLength: 8)
                trailing
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MagicColor.textSecondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 47)
            .contentShape(Rectangle())
            .background(background)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isOpen)
    }

    @ViewBuilder
    private var trailing: some View {
        if action == nil, inherited != nil {
            // Inherited from the default profile — a small tag.
            Text("Default")
                .font(MagicFont.text(10, weight: .semibold))
                .kerning(0.4)
                .foregroundStyle(MagicColor.textSecondary)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(MagicColor.surfaceSunken))
                .fixedSize()
        } else if let hint = action?.shortcutHint, !hint.isEmpty {
            Text(hint)
                .font(MagicFont.text(11, weight: .medium))
                .foregroundStyle(MagicColor.textSecondary)
                .fixedSize()
        }
    }

    private var iconSquare: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(MagicColor.surfaceSunken)
                .frame(width: 30, height: 30)
            Image(systemName: shown?.icon ?? "plus")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(assigned ? MagicColor.textPrimary : MagicColor.textTertiary)
        }
    }

    private var background: some View {
        // Sits on the warm "selected key" panel, so rows are white and lift on
        // hover; the open row gets a Dawn accent border.
        let fill = (isHovered && !isOpen) ? MagicColor.surfaceSunken : MagicColor.surfaceCard
        let stroke = isOpen ? MagicColor.borderAccent : MagicColor.borderSubtle
        return RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(fill)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(stroke, lineWidth: isOpen ? 1.5 : 1))
    }
}
