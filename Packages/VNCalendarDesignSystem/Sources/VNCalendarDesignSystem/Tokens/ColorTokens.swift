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

    // MARK: - Legacy Named Base Tokens (fixed, non-adaptive; repointed to the neutral VNPalette)
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
    /// Decorative gold (#C5A059); not for text
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

    // MARK: - Semantic Adaptive Tokens (Neutral Porcelain + Jade, values in VNPalette)
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

    public static let backgroundPrimary: Pair = (0xF6F7F4, 0x131415)
    public static let backgroundSecondary: Pair = (0xFFFFFF, 0x1C1E1F)
    public static let backgroundTertiary: Pair = (0xECEEEA, 0x26292A)
    public static let surfaceElevated: Pair = (0xFFFFFF, 0x26292A)

    public static let textPrimary: Pair = (0x1B1D1F, 0xF2F1EC)
    public static let textSecondary: Pair = (0x4A4F52, 0xB4B7B5)
    public static let textTertiary: Pair = (0x666C70, 0x8E9391)

    public static let accentHeritageRed: Pair = (0xB5341D, 0xE8715C)
    public static let accentDeepPrimary: Pair = (0x8F2410, 0xD9534F)
    public static let accentImperialGold: Pair = (0xC5A059, 0xE3C781)
    public static let accentGoldText: Pair = (0x7A5C14, 0xE3C781)
    public static let accentJade: Pair = (0x2F6B57, 0x6FBF9F)
    public static let accentJadeSurface: Pair = (0xE3EFEA, 0x1E3A31)
    public static let accentRedSurface: Pair = (0xF8E6E1, 0x3A1D1A)
    public static let accentGoldSurface: Pair = (0xF8F2E4, 0x332B1A)
    public static let goldContainer: Pair = (0xF6E7BF, 0x5D4201)
    public static let onGoldContainer: Pair = (0x6B4E0E, 0xFFDEA5)
    public static let onAccent: Pair = (0xFFFFFF, 0x131415)

    public static let borderSubtle: Pair = (0xDADDD8, 0x2E3133)
    public static let borderStrong: Pair = (0x8A9094, 0x6E7375)

    public static let statusSuccess: Pair = (0x2E6F40, 0x5DB67E)
    public static let statusWarning: Pair = (0x9A5300, 0xE9A23B)
    public static let statusError: Pair = (0xB91C1C, 0xF08A82)
}
