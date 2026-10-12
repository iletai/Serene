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

    // MARK: - Semantic Adaptive Tokens
    /// Nền chính: Gạo Mới (#FEF9F1) / Than Mài (#181614)
    static let vnBackgroundPrimary = Color(light: vnNewRiceIvory, dark: vnLacquerCharcoal)

    /// Nền bề mặt thẻ nâng cao: Vải Xô (#F8F3EB) / Gỗ Mun Ấm (#24201D)
    static let vnBackgroundSecondary = Color(light: vnWovenLinen, dark: vnWarmEbony)

    /// Nền nhóm / chip / bề mặt cấp 3: Bãi Cát (#ECE8E0) / Gỗ Mun Tối (#2E2925)
    static let vnBackgroundTertiary = Color(light: vnAncientSand, dark: vnDarkSand)

    /// Nền bề mặt nổi (sheets / nav pill / popovers): Trắng (#FFFFFF) / Gỗ Mun Tối (#2E2925)
    static let vnSurfaceElevated = Color(light: Color(hex: 0xFFFFFF), dark: vnDarkSand)

    /// Chữ chính / số: Mực Nho (#1D1C17) / Giấy Dó Trắng (#FAF7F0)
    static let vnTextPrimary = Color(light: vnDeepCalligraphicInk, dark: vnRicePaperWhite)

    /// Chữ phụ / ngày âm: Tro Bếp (#59413C) / Khói Mờ (#A89F91)
    static let vnTextSecondary = Color(light: vnHearthAshGray, dark: vnMutedHearth)
    static let vnHearthAsh = vnTextSecondary

    /// Chữ thứ ba / ngoài tháng: Khói Lam (#8D706B) / Tro Bếp (#59413C)
    static let vnTextTertiary = Color(light: vnMistGray, dark: vnHearthAshGray)

    /// Điểm nhấn Đỏ: Đỏ Chu Sa (#C23B22) / Than Tàn Đỏ (#D9534F)
    static let vnAccentHeritageRed = Color(light: vnCinnabarLacquerRed, dark: vnCinnabarEmbers)
    static let vnCinnabarRed = vnAccentHeritageRed

    /// Điểm nhấn Đỏ Đậm (text/icon trên nền sáng): (#A0220B) / Than Tàn Đỏ (#D9534F)
    static let vnAccentDeepPrimary = Color(light: vnVermilionDark, dark: vnCinnabarEmbers)

    /// Điểm nhấn Vàng: Hoàng Cúc (#C5A059) / Đồng Thau Cổ (#E9CB8F)
    static let vnAccentImperialGold = Color(light: vnImperialChrysanthemumGold, dark: vnAntiqueBrass)
    static let vnChrysanthemumGold = vnAccentImperialGold

    /// Nền Đỏ Son Nhạt thích ứng
    static let vnAccentRedSurface = Color(light: vnVermilionSurface, dark: Color(hex: 0x3A1D1A))

    /// Nền Vàng Quỳ Nhạt thích ứng
    static let vnAccentGoldSurface = Color(light: vnGoldSurface, dark: Color(hex: 0x332B1A))

    /// Container Vàng (chips / status pill "Hôm nay"): (#FED488) / (#5D4201)
    static let vnGoldContainer = Color(light: Color(hex: 0xFED488), dark: Color(hex: 0x5D4201))

    /// Chữ trên Container Vàng: (#785A1A) / (#FFDEA5)
    static let vnOnGoldContainer = Color(light: Color(hex: 0x785A1A), dark: Color(hex: 0xFFDEA5))

    /// Đường viền phân cách: Nếp Cũ Tre Mộc (#E1BFB8) / Viền Tối (#38322D)
    static let vnBorderSubtle = Color(light: vnOldRiceBorder, dark: vnDarkBorder)

    /// Trạng thái thành công / Lá Tre (#2E6F40)
    static let vnStatusSuccess = Color(light: Color(hex: 0x2E6F40), dark: Color(hex: 0x3E8E55))
    static let vnBambooLeafGreen = vnStatusSuccess

    /// Trạng thái cảnh báo / Hổ Phách (#D97706)
    static let vnStatusWarning = Color(light: Color(hex: 0xD97706), dark: Color(hex: 0xE58E26))

    /// Trạng thái lỗi / Huyết Dụ (#B91C1C)
    static let vnStatusError = Color(light: Color(hex: 0xB91C1C), dark: Color(hex: 0xD9534F))
}
