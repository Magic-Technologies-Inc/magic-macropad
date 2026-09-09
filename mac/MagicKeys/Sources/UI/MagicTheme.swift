import AppKit
import CoreText
import SwiftUI

// The Magic palette, ported from iOS/Magic/DesignSystem/Tokens (Brand Guidelines p.10).
// Neutrals are Prussian-warmed, never pure grey. One Dawn element per screen, maximum.

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

extension Color {
    /// Resolves differently in light and dark appearance.
    init(light: NSColor, dark: NSColor) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }

    init(hex: UInt32, opacity: Double = 1) {
        self.init(nsColor: NSColor(hex: hex, alpha: opacity))
    }
}

enum MagicColor {
    // Brand palette
    static let prussian = Color(hex: 0x052B42)
    static let cerulean = Color(hex: 0x1C3792)
    static let sky = Color(hex: 0xA7C5F1)
    static let tailwind = Color(hex: 0xFBEED5)
    static let horizon = Color(hex: 0xFFB786)
    static let dawn = Color(hex: 0xE3520C)

    // Neutrals (Prussian-derived)
    static let ink = Color(hex: 0x050607)
    static let graphite = Color(hex: 0x14181C)
    static let slate900 = Color(hex: 0x1E252B)
    static let slate700 = Color(hex: 0x3A444C)
    static let slate500 = Color(hex: 0x68757F)
    static let slate300 = Color(hex: 0xA6B0B8)
    static let slate200 = Color(hex: 0xCCD3D8)
    static let slate100 = Color(hex: 0xE6EAED)
    static let slate50 = Color(hex: 0xF4F6F7)
    static let paper = Color(hex: 0xFFFFFF)

    // Semantic — text
    static let textPrimary = Color(light: NSColor(hex: 0x050607), dark: NSColor(hex: 0xFFFFFF))
    static let textSecondary = Color(light: NSColor(hex: 0x68757F), dark: NSColor(hex: 0xFFFFFF, alpha: 0.62))
    static let textTertiary = Color(light: NSColor(hex: 0xA6B0B8), dark: NSColor(hex: 0xFFFFFF, alpha: 0.38))

    // Semantic — surface
    static let surfacePage = Color(light: NSColor(hex: 0xFFFFFF), dark: NSColor(hex: 0x050607))
    static let surfacePageAlt = Color(light: NSColor(hex: 0xF4F6F7), dark: NSColor(hex: 0x14181C))
    static let surfaceCard = Color(light: NSColor(hex: 0xFFFFFF), dark: NSColor(hex: 0x14181C))
    static let surfaceSunken = Color(light: NSColor(hex: 0xE6EAED), dark: NSColor(hex: 0x0C0F12))
    static let surfaceAccentSoft = Color(light: NSColor(hex: 0xFCEBE1), dark: NSColor(hex: 0xE3520C, alpha: 0.18))
    // Frosted panel material (over the desktop behind a popover).
    static let surfaceGlass = Color(light: NSColor(hex: 0xF6F7F8, alpha: 0.92), dark: NSColor(hex: 0x14181C, alpha: 0.82))

    // Semantic — border
    static let borderSubtle = Color(light: NSColor(hex: 0xE6EAED), dark: NSColor(hex: 0xFFFFFF, alpha: 0.08))
    static let borderDefault = Color(light: NSColor(hex: 0xCCD3D8), dark: NSColor(hex: 0xFFFFFF, alpha: 0.14))
    static let borderAccent = dawn
    static let borderHairline = Color(light: NSColor(hex: 0x052B42, alpha: 0.10), dark: NSColor(hex: 0xFFFFFF, alpha: 0.08))

    // Interactive accent for text/icons — cerulean in light, Sky in dark so it
    // stays readable on dark surfaces (matches the design system's text-link).
    static let accentBlue = Color(light: NSColor(hex: 0x1C3792), dark: NSColor(hex: 0xA7C5F1))

    // State
    static let stateSuccess = Color(hex: 0x1E7A54)

    static let deviceBackdrop = Color(light: NSColor(hex: 0xEDF3FC), dark: NSColor(hex: 0x0A1119))
}

enum MagicFont {
    /// Advercase — display face for titles and the device's key numerals.
    static func display(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "Advercase-Bold" : "Advercase-Regular", size: size)
    }

    /// Inter — text face for everything else.
    static func text(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold: name = "Inter-Bold"
        case .semibold: name = "Inter-SemiBold"
        case .medium: name = "Inter-Medium"
        default: name = "Inter-Regular"
        }
        return .custom(name, size: size)
    }

    /// Registers the bundled brand fonts for this process. Call once at launch.
    static func registerBundledFonts() {
        let names = ["Advercase-Regular", "Advercase-Bold",
                     "Inter-Regular", "Inter-Medium", "Inter-SemiBold", "Inter-Bold"]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
