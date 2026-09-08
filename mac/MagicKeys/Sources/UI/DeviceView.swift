import SwiftUI

/// The K1 rendered as hardware: a thin aluminum bar with three keys, drawn
/// upright the way it sits along the MacBook's edge. Keys are clickable;
/// the selected key carries the screen's single Dawn accent.
struct DeviceView: View {
    @Binding var selectedKey: Int
    @State private var hoveredKey: Int?

    var body: some View {
        ZStack {
            deviceBody
            VStack(spacing: 18) {
                ForEach(0..<3, id: \.self) { key in
                    keyCap(key)
                }
            }
            .padding(.top, 26)
        }
        .frame(width: 128, height: 396)
    }

    private var deviceBody: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(LinearGradient(
                colors: [Color(hex: 0x2A3138), Color(hex: 0x14181C), Color(hex: 0x1E252B)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(LinearGradient(
                        colors: [.white.opacity(0.22), .white.opacity(0.04), .clear],
                        startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                // USB-C plug stub, near the rear (top) on the laptop-facing side.
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(Color(hex: 0x3A444C))
                    .frame(width: 10, height: 34)
                    .offset(x: 8, y: 42)
            }
            .shadow(color: .black.opacity(0.45), radius: 28, y: 18)
    }

    private func keyCap(_ key: Int) -> some View {
        let isSelected = selectedKey == key
        let isHovered = hoveredKey == key
        return Button {
            selectedKey = key
        } label: {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(
                    colors: isHovered && !isSelected
                        ? [Color(hex: 0x232A31), Color(hex: 0x171C21)]
                        : [Color(hex: 0x1B2127), Color(hex: 0x111519)],
                    startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            isSelected
                                ? AnyShapeStyle(MagicColor.dawn)
                                : AnyShapeStyle(Color.white.opacity(isHovered ? 0.22 : 0.10)),
                            lineWidth: isSelected ? 2 : 1)
                )
                .overlay(
                    Text("\(key + 1)")
                        .font(MagicFont.display(26))
                        .foregroundStyle(isSelected ? MagicColor.dawn : Color(hex: 0x68757F))
                )
                .frame(width: 88, height: 88)
                .shadow(color: isSelected ? MagicColor.dawn.opacity(0.35) : .clear,
                        radius: 16)
        }
        .buttonStyle(.plain)
        .onHover { hovering in hoveredKey = hovering ? key : (hoveredKey == key ? nil : hoveredKey) }
        .animation(.easeOut(duration: 0.15), value: selectedKey)
        .animation(.easeOut(duration: 0.15), value: hoveredKey)
    }
}
