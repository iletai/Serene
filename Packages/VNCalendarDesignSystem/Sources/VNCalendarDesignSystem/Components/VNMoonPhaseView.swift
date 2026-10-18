import SwiftUI

public enum VNMoonPhaseType: String, Sendable, Codable, CaseIterable {
    case newMoon = "Trăng Non"                 // Mùng 1 ÂL
    case waxingCrescent = "Trăng Lưỡi Liềm Đầu Tháng" // Mùng 2 - 6 ÂL
    case firstQuarter = "Trăng Thượng Huyền"    // Mùng 7 - 9 ÂL
    case waxingGibbous = "Trăng Khuyết Dần Đầy" // Mùng 10 - 14 ÂL
    case fullMoon = "Trăng Tròn (Rằm)"          // Ngày 15 ÂL
    case waningGibbous = "Trăng Khuyết Dần Vơi" // Ngày 16 - 21 ÂL
    case lastQuarter = "Trăng Hạ Huyền"         // Ngày 22 - 24 ÂL
    case waningCrescent = "Trăng Tàn Cuối Tháng" // Ngày 25 - 30 ÂL

    public static func from(lunarDay: Int) -> VNMoonPhaseType {
        switch lunarDay {
        case 1:
            return .newMoon
        case 2...6:
            return .waxingCrescent
        case 7...9:
            return .firstQuarter
        case 10...14:
            return .waxingGibbous
        case 15:
            return .fullMoon
        case 16...21:
            return .waningGibbous
        case 22...24:
            return .lastQuarter
        case 25...30:
            return .waningCrescent
        default:
            return .newMoon
        }
    }
}

public struct VNMoonPhaseView: View {
    public let lunarDay: Int
    public let size: CGFloat
    public let showTitle: Bool

    public init(lunarDay: Int, size: CGFloat = VNSpacing.xxl, showTitle: Bool = false) {
        self.lunarDay = max(1, min(30, lunarDay))
        self.size = size
        self.showTitle = showTitle
    }

    private var phaseType: VNMoonPhaseType {
        VNMoonPhaseType.from(lunarDay: lunarDay)
    }

    private var illuminationPercent: Int {
        // Approximate visual illumination percent based on lunar day
        if lunarDay == 15 { return 100 }
        if lunarDay == 1 { return 0 }
        if lunarDay < 15 {
            return Int(Double(lunarDay - 1) / 14.0 * 100.0)
        } else {
            return Int(Double(30 - lunarDay) / 15.0 * 100.0)
        }
    }

    public var body: some View {
        HStack(spacing: VNSpacing.xs) {
            ZStack {
                // Background disc tinted by phase: gold for full moon, neutral otherwise
                Circle()
                    .fill(isFullMoon ? Color.vnGoldContainer : Color.vnBackgroundTertiary)
                    .frame(width: size, height: size)

                // Moon icon based on phase
                Image(systemName: moonSystemIcon)
                    .font(.system(size: size * 0.82))
                    .foregroundColor(isFullMoon ? Color.vnOnGoldContainer : Color.vnTextSecondary)
                    .shadow(
                        color: isFullMoon ? Color.vnAccentImperialGold.opacity(0.35) : Color.clear,
                        radius: isFullMoon ? VNShadow.card.radius : 0
                    )
            }

            if showTitle {
                VStack(alignment: .leading, spacing: VNSpacing.space2) {
                    Text(phaseType.rawValue)
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .foregroundColor(isFullMoon ? .vnAccentHeritageRed : .vnTextPrimary)

                    Text("\(illuminationPercent)% sáng")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.vnTextSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(phaseType.rawValue), \(illuminationPercent)% sáng")
    }

    private var isFullMoon: Bool {
        lunarDay == 15
    }

    private var moonSystemIcon: String {
        switch lunarDay {
        case 1:
            return "moonphase.new.moon"
        case 2...5:
            return "moonphase.waxing.crescent"
        case 6...9:
            return "moonphase.first.quarter"
        case 10...14:
            return "moonphase.waxing.gibbous"
        case 15:
            return "moonphase.full.moon"
        case 16...20:
            return "moonphase.waning.gibbous"
        case 21...24:
            return "moonphase.last.quarter"
        case 25...30:
            return "moonphase.waning.crescent"
        default:
            return "moonphase.new.moon"
        }
    }
}
