#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI

public extension Color {
    // MARK: - Vietnamese Heritage Hex Initializer
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xff) / 255.0
        let green = Double((hex >> 8) & 0xff) / 255.0
        let blue = Double(hex & 0xff) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    // MARK: - Dynamic Light / Dark Initializer
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        #if os(watchOS)
        self = light
        #else
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #endif
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
        }))
        #else
        self = light
        #endif
    }

    // MARK: - Legacy Named Base Tokens (fixed, non-adaptive; repointed to VNPalette)
    private static func light(_ pair: (light: UInt32, dark: UInt32)) -> Color { Color(hex: UInt(pair.light)) }
    private static func dark(_ pair: (light: UInt32, dark: UInt32)) -> Color { Color(hex: UInt(pair.dark)) }

    static let vnNewRiceIvory = light(VNPalette.backgroundPrimary)
    static let vnWovenLinen = light(VNPalette.backgroundSecondary)
    static let vnContainerSurface = light(VNPalette.backgroundTertiary)
    static let vnAncientSand = light(VNPalette.backgroundTertiary)
    static let vnDeepCalligraphicInk = light(VNPalette.textPrimary)
    static let vnHearthAshGray = light(VNPalette.textSecondary)
    static let vnMistGray = light(VNPalette.textTertiary)
    static let vnCinnabarLacquerRed = light(VNPalette.accentHeritageRed)
    static let vnVermilionDark = light(VNPalette.accentDeepPrimary)
    static let vnVermilionSurface = light(VNPalette.accentRedSurface)
    /// Decorative mai yellow (#FFC21A); not for text
    static let vnImperialChrysanthemumGold = light(VNPalette.accentImperialGold)
    static let vnGoldSurface = light(VNPalette.accentGoldSurface)
    static let vnOldRiceBorder = light(VNPalette.borderSubtle)

    static let vnLacquerCharcoal = dark(VNPalette.backgroundPrimary)
    static let vnWarmEbony = dark(VNPalette.backgroundSecondary)
    static let vnDarkSand = dark(VNPalette.backgroundTertiary)
    static let vnRicePaperWhite = dark(VNPalette.textPrimary)
    static let vnMutedHearth = dark(VNPalette.textSecondary)
    static let vnCinnabarEmbers = dark(VNPalette.accentHeritageRed)
    static let vnAntiqueBrass = dark(VNPalette.accentImperialGold)
    static let vnDarkBorder = dark(VNPalette.borderSubtle)

    // MARK: - Semantic Adaptive Tokens (Phố Đèn Lồng, values in VNPalette)
    private static func palette(_ pair: (light: UInt32, dark: UInt32)) -> Color {
        Color(light: Color(hex: UInt(pair.light)), dark: Color(hex: UInt(pair.dark)))
    }

    static let vnBackgroundPrimary = palette(VNPalette.backgroundPrimary)
    static let vnBackgroundSecondary = palette(VNPalette.backgroundSecondary)
    static let vnBackgroundTertiary = palette(VNPalette.backgroundTertiary)
    /// Sheets / nav pill / popovers
    static let vnSurfaceElevated = palette(VNPalette.surfaceElevated)

    static let vnTextPrimary = palette(VNPalette.textPrimary)
    static let vnTextSecondary = palette(VNPalette.textSecondary)
    static let vnHearthAsh = vnTextSecondary
    static let vnTextTertiary = palette(VNPalette.textTertiary)

    /// Red accent (Giỗ, Mùng 1, Rằm)
    static let vnAccentHeritageRed = palette(VNPalette.accentHeritageRed)
    static let vnCinnabarRed = vnAccentHeritageRed
    /// Deep red for text/icons on light surfaces
    static let vnAccentDeepPrimary = palette(VNPalette.accentDeepPrimary)

    /// Decorative gold only (fails AA as text); use vnAccentGoldText for text
    static let vnAccentImperialGold = palette(VNPalette.accentImperialGold)
    static let vnChrysanthemumGold = vnAccentImperialGold
    static let vnAccentGoldText = palette(VNPalette.accentGoldText)

    static let vnAccentJade = palette(VNPalette.accentJade)
    static let vnAccentJadeSurface = palette(VNPalette.accentJadeSurface)
    static let vnAccentRedSurface = palette(VNPalette.accentRedSurface)
    static let vnAccentGoldSurface = palette(VNPalette.accentGoldSurface)

    /// Hội An blue: festivals, links, informational accents
    static let vnAccentSky = palette(VNPalette.accentSky)
    static let vnAccentSkySurface = palette(VNPalette.accentSkySurface)
    /// Hoa Đào pink: decoration only, never text
    static let vnAccentBlossom = palette(VNPalette.accentBlossom)
    /// Fixed lunar-night card ground and its foreground
    static let vnNight = palette(VNPalette.night)
    static let vnOnNight = palette(VNPalette.onNight)

    /// Gold container (chips / "Hôm nay" pill) and its foreground
    static let vnGoldContainer = palette(VNPalette.goldContainer)
    static let vnOnGoldContainer = palette(VNPalette.onGoldContainer)

    /// Foreground on red / jade accent fills
    static let vnOnAccent = palette(VNPalette.onAccent)

    static let vnBorderSubtle = palette(VNPalette.borderSubtle)
    static let vnBorderStrong = palette(VNPalette.borderStrong)

    static let vnStatusSuccess = palette(VNPalette.statusSuccess)
    static let vnBambooLeafGreen = vnStatusSuccess
    static let vnStatusWarning = palette(VNPalette.statusWarning)
    static let vnStatusError = palette(VNPalette.statusError)
}

/// Raw hex pairs for every semantic token. Single source of truth, also used by contrast tests.
public enum VNPalette {
    public typealias Pair = (light: UInt32, dark: UInt32)

    public static let backgroundPrimary: Pair = (0xF4F5FA, 0x0D0E1C)
    public static let backgroundSecondary: Pair = (0xFFFFFF, 0x171930)
    public static let backgroundTertiary: Pair = (0xE9EBF4, 0x22254A)
    public static let surfaceElevated: Pair = (0xFFFFFF, 0x22254A)

    public static let textPrimary: Pair = (0x15162B, 0xF5F4FF)
    public static let textSecondary: Pair = (0x464868, 0xB9BAD9)
    public static let textTertiary: Pair = (0x62658A, 0x8C8FB8)

    public static let accentHeritageRed: Pair = (0xCC1636, 0xFF5A6E)
    public static let accentDeepPrimary: Pair = (0xB0102E, 0xFF8593)
    public static let accentImperialGold: Pair = (0xFFC21A, 0xFFC940)
    public static let accentGoldText: Pair = (0x8A5300, 0xFFD25E)
    public static let accentJade: Pair = (0x007A55, 0x3DDBA0)
    public static let accentJadeSurface: Pair = (0xDDF7EC, 0x0E3328)
    public static let accentRedSurface: Pair = (0xFFE4E9, 0x3D1426)
    public static let accentGoldSurface: Pair = (0xFFF7DB, 0x2E2712)
    public static let accentSky: Pair = (0x1F5FE0, 0x7FA8FF)
    public static let accentSkySurface: Pair = (0xE2EBFF, 0x17264F)
    public static let accentBlossom: Pair = (0xFF7AA2, 0xFF8FB1)
    public static let goldContainer: Pair = (0xFFF0B8, 0x4A3600)
    public static let onGoldContainer: Pair = (0x6E4300, 0xFFE08A)
    public static let onAccent: Pair = (0xFFFFFF, 0x0D0E1C)
    /// Fixed lunar-night indigo in both themes (hero daily-sheet card, artwork grounds).
    public static let night: Pair = (0x191B45, 0x191B45)
    public static let onNight: Pair = (0xF5F4FF, 0xF5F4FF)

    public static let borderSubtle: Pair = (0xDDE0EC, 0x2C2F55)
    public static let borderStrong: Pair = (0x767BA0, 0x6F74A3)

    public static let statusSuccess: Pair = (0x007A55, 0x3DDBA0)
    public static let statusWarning: Pair = (0xA35200, 0xFFB547)
    public static let statusError: Pair = (0xC8102E, 0xFF7A85)
}
