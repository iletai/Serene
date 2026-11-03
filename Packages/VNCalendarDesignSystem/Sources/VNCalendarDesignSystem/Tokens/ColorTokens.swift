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

    // MARK: - Light Mode Base Tokens (Vietnamese Lunar Editorial - Authentic Materiality)
    /// Gạo Mới / Giấy Dó (#FEF9F1) - Canvas Background
    static let vnNewRiceIvory = Color(hex: 0xFEF9F1)

    /// Vải Xô Nâng Cấp (#F8F3EB) - Elevated Card Surfaces Level 1
    static let vnWovenLinen = Color(hex: 0xF8F3EB)

    /// Khung Đệm Vải Dệt (#EFE8DC) - Container Surface Level 2
    static let vnContainerSurface = Color(hex: 0xEFE8DC)

    /// Bãi Cát Cổ (#ECE8E0) - Tertiary Surface & Group Chips
    static let vnAncientSand = Color(hex: 0xECE8E0)

    /// Mực Tàu Nho (#1D1C17) - Primary Typography & Numerals
    static let vnDeepCalligraphicInk = Color(hex: 0x1D1C17)

    /// Tro Bếp Trầm (#59413C) - Secondary Meta & Lunar Dates
    static let vnHearthAshGray = Color(hex: 0x59413C)

    /// Khói Lam Mờ (#8D706B) - Tertiary Text & Placeholders
    static let vnMistGray = Color(hex: 0x8D706B)

    /// Đỏ Son Chu Sa (#C23B22) - Primary Accent (Giỗ, Mùng 1, Rằm 15 ÂL, Ấn Triện)
    static let vnCinnabarLacquerRed = Color(hex: 0xC23B22)

    /// Đỏ Son Đậm (#A0220B) - Dark Vermilion (Nút ấn, Viền đậm)
    static let vnVermilionDark = Color(hex: 0xA0220B)

    /// Nền Son Nhạt (#F5E3DA) - Soft Vermilion Tint Surface
    static let vnVermilionSurface = Color(hex: 0xF5E3DA)

    /// Vàng Quỳ Hoàng Cúc (#C5A059) - Accent Gold (Tiết Khí, Hoàng Đạo)
    static let vnImperialChrysanthemumGold = Color(hex: 0xC5A059)

    /// Nền Vàng Quỳ Nhạt (#F8F2E4) - Soft Gold Tint Surface
    static let vnGoldSurface = Color(hex: 0xF8F2E4)

    /// Tre Già Viền Mộc (#E1BFB8) - Hairline Dividers & Frames
    static let vnOldRiceBorder = Color(hex: 0xE1BFB8)

    // MARK: - Dark Mode Base Tokens
    /// Than Mài (#181614) - Canvas Background Dark
    static let vnLacquerCharcoal = Color(hex: 0x181614)

    /// Gỗ Mun Ấm (#24201D) - Elevated Cards Dark
    static let vnWarmEbony = Color(hex: 0x24201D)

    /// Gỗ Mun Tối (#2E2925) - Tertiary Surface Dark
    static let vnDarkSand = Color(hex: 0x2E2925)

    /// Giấy Dó Trắng (#FAF7F0) - Primary Text Dark
    static let vnRicePaperWhite = Color(hex: 0xFAF7F0)

    /// Khói Mờ (#A89F91) - Secondary Text Dark
    static let vnMutedHearth = Color(hex: 0xA89F91)

    /// Than Tàn Đỏ (#D9534F) - Accent Red Dark
    static let vnCinnabarEmbers = Color(hex: 0xD9534F)

    /// Đồng Thau Cổ (#E9CB8F) - Accent Gold Dark
    static let vnAntiqueBrass = Color(hex: 0xE9CB8F)

    /// Viền Tối (#38322D) - Hairline Divider Dark
    static let vnDarkBorder = Color(hex: 0x38322D)

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
    public static let textTertiary: Pair = (0x6A7074, 0x8E9391)

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

    public static let borderSubtle: Pair = (0xDADDD8, 0x38322D)
    public static let borderStrong: Pair = (0x8C9296, 0x6E7375)

    public static let statusSuccess: Pair = (0x2E6F40, 0x5DB67E)
    public static let statusWarning: Pair = (0x9A5300, 0xE9A23B)
    public static let statusError: Pair = (0xB91C1C, 0xF08A82)
}
