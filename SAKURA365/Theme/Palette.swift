import SwiftUI

/// SAKURA 365 palette — a quiet Japanese garden at dusk.
/// The app is dark-only; these values are never swapped for a light variant.
enum Palette {
    /// Midnight — app background.
    static let midnight      = Color(hex: 0x101113)
    /// Charcoal — cards and grouped surfaces.
    static let charcoal      = Color(hex: 0x202126)
    /// Deep illustration background behind the tree.
    static let illustration  = Color(hex: 0x17171C)
    /// Dusty Sakura — primary accent.
    static let dustySakura   = Color(hex: 0xB77D91)
    /// Blossom — light petal tone.
    static let blossom       = Color(hex: 0xD5B7BC)
    /// Moonlight — primary text.
    static let moonlight     = Color(hex: 0xC5BFB4)
    /// Secondary text.
    static let secondaryText = Color(hex: 0x8D8780)
    /// Muted Moss — quiet secondary accent (ground, confirmations).
    static let moss          = Color(hex: 0x657268)

    // Derived, understated tones.
    /// Hairline borders and separators.
    static let hairline      = Color(hex: 0xC5BFB4).opacity(0.08)
    /// Slightly raised surface used for pressed rows.
    static let charcoalRaised = Color(hex: 0x26272D)

    // Illustration-only tones.
    static let branch        = Color(hex: 0x3E3836)   // deep warm grey
    static let branchLit     = Color(hex: 0x5C534E)   // moonlit edge
    static let bark          = Color(hex: 0x2A2526)   // ink grain
    static let mutedRose     = Color(hex: 0x9C6676)   // third blossom tone
    static let blossomCenter = Color(hex: 0x502834).opacity(0.55)

    /// The three blossom tones, indexed by a blossom's deterministic `tone`.
    static let blossomTones: [Color] = [dustySakura, blossom, mutedRose]
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// Small typographic helpers: quiet, tracked uppercase labels.
extension View {
    func sakuraCaption(_ color: Color = Palette.secondaryText) -> some View {
        self.font(.system(size: 13, weight: .regular))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}
