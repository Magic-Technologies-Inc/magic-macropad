import SwiftUI

/// The K1 drawn as physical hardware: three keycaps in a dark holder with a
/// USB-C plug stub. The selected key wears the warm Tailwind→Horizon accent.
struct KeycapDeviceView: View {
    @Binding var selectedKey: Int
    var boundCounts: [Int]   // number of assigned gestures per key (for the title)

    var body: some View {
        holder
            .overlay(alignment: .topLeading) { plugStub }
    }

    private var holder: some View {
        VStack(spacing: 9) {
            ForEach(0..<3, id: \.self) { key in
                keycap(key)
            }
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: 0x3A444C), Color(hex: 0x1E252B), Color(hex: 0x14181C)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color(hex: 0x052B42).opacity(0.32), radius: 12, y: 12)
    }

    private var plugStub: some View {
        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0xE6EAED), Color(hex: 0xA6B0B8), Color(hex: 0x68757F)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: 20, height: 14)
            .overlay(RoundedRectangle(cornerRadius: 2.5).strokeBorder(.white.opacity(0.5), lineWidth: 0.5))
            .offset(x: -11, y: 20)
    }

    private func keycap(_ key: Int) -> some View {
        Button {
            selectedKey = key
        } label: {
            KeyCapLabel(number: key + 1, selected: selectedKey == key)
        }
        .buttonStyle(.plain)
        .help(helpText(key))
        .animation(.easeOut(duration: 0.14), value: selectedKey)
    }

    private func helpText(_ key: Int) -> String {
        let bound = boundCounts.indices.contains(key) ? boundCounts[key] : 0
        return "Key \(key + 1) · \(bound > 0 ? "\(bound) assigned" : "unassigned")"
    }
}

/// One keycap face — extracted so the compiler can type-check the modifier chain.
private struct KeyCapLabel: View {
    let number: Int
    let selected: Bool

    private var capGradient: LinearGradient {
        let colors = selected
            ? [Color(hex: 0xFBEED5), Color(hex: 0xFFB786), Color(hex: 0xE8A272)]
            : [Color(hex: 0xE6EAED), Color(hex: 0xCCD3D8), Color(hex: 0xA6B0B8)]
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    private var bevelColor: Color { selected ? Color(hex: 0xB87B4F) : Color(hex: 0x68757F) }
    private var faceStroke: Color {
        selected ? Color(hex: 0x784820).opacity(0.22) : Color(hex: 0x052B42).opacity(0.14)
    }

    var body: some View {
        ZStack {
            cap
            face
            Text("\(number)")
                .font(MagicFont.display(17))
                .foregroundStyle(selected ? Color(hex: 0x5A3312) : MagicColor.slate700)
        }
        .frame(width: 62, height: 62)
    }

    private var cap: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(capGradient)
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(.white.opacity(selected ? 0.5 : 0.4), lineWidth: 1))
            .shadow(color: bevelColor, radius: 0, y: 3)
            .shadow(color: Color(hex: 0x050607).opacity(selected ? 0.40 : 0.35), radius: 6, y: 6)
    }

    private var face: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(LinearGradient(colors: [.white.opacity(0.34), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(faceStroke, lineWidth: 1))
            .padding(5)
    }
}
