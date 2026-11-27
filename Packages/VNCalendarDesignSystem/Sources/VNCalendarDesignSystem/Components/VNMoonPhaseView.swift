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

    /// Localized display name (rawValue stays the stable Codable value).
    public var localizedName: String {
        switch self {
        case .newMoon: String(localized: "ds.moon.phase.1")
        case .waxingCrescent: String(localized: "ds.moon.phase.2")
        case .firstQuarter: String(localized: "ds.moon.phase.3")
        case .waxingGibbous: String(localized: "ds.moon.phase.4")
        case .fullMoon: String(localized: "ds.moon.phase.5")
        case .waningGibbous: String(localized: "ds.moon.phase.6")
        case .lastQuarter: String(localized: "ds.moon.phase.7")
        case .waningCrescent: String(localized: "ds.moon.phase.8")
        }
    }

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

/// Lit part of the moon for a lunar day (design.html `moonSVG`): a semicircle plus an elliptical terminator.
/// Lunar day 1 (new moon) has no lit area. Works for any day, including 30-day months.
public struct VNMoonPhaseShape: Shape {
    public let lunarDay: Int
    private static let samples = 64

    public init(lunarDay: Int) {
        self.lunarDay = lunarDay
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        guard lunarDay != 1 else { return path }
        let phase = Double(lunarDay - 1) / 29.53
        let cosine = cos(2 * .pi * phase)
        let waxing = phase < 0.5
        let radius = min(rect.width, rect.height) / 2
        let centerX = rect.midX
        let centerY = rect.midY
        let limbSide: CGFloat = waxing ? 1 : -1
        let terminatorSide: CGFloat = (cosine > 0) == waxing ? 1 : -1
        let terminatorRadius = radius * abs(cosine)
        path.move(to: CGPoint(x: centerX, y: centerY - radius))
        for step in 1...Self.samples {
            let angle = Double(step) / Double(Self.samples) * .pi
            path.addLine(to: CGPoint(x: centerX + limbSide * radius * sin(angle), y: centerY - radius * cos(angle)))
        }
        for step in 1...Self.samples {
            let angle = Double(step) / Double(Self.samples) * .pi
            path.addLine(to: CGPoint(
                x: centerX + terminatorSide * terminatorRadius * sin(angle),
                y: centerY + radius * cos(angle)
            ))
        }
        path.closeSubpath()
        return path
    }
}

/// Moon disc: dark side, lit phase, hairline rim. `onArt` uses the translucent white dark side meant for photo backgrounds.
public struct VNMoonDisc: View {
    public let lunarDay: Int
    public let size: CGFloat
    public let onArt: Bool

    public init(lunarDay: Int, size: CGFloat, onArt: Bool = false) {
        self.lunarDay = max(1, min(30, lunarDay))
        self.size = size
        self.onArt = onArt
    }

    public var body: some View {
        ZStack {
            Circle().fill(onArt ? Color.white.opacity(0.16) : Color(light: Color(hex: 0xDDE3EF), dark: Color(hex: 0x2A3350)))
            VNMoonPhaseShape(lunarDay: lunarDay).fill(Color.vnAccentImperialGold)
            Circle().strokeBorder(
                Color(light: Color(hex: 0x0E1526, alpha: 0.18), dark: Color(hex: 0xF1F4FA, alpha: 0.16)),
                lineWidth: max(0.5, size * 0.8 / 24)
            )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
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
            VNMoonDisc(lunarDay: lunarDay, size: size)

            if showTitle {
                VStack(alignment: .leading, spacing: VNSpacing.space2) {
                    Text(phaseType.localizedName)
                        .font(.vnDisplay(size: 11, weight: .semibold))
                        .foregroundColor(isFullMoon ? .vnAccentHeritageRed : .vnTextPrimary)

                    Text(String(format: String(localized: "ds.moon.illumination"), illuminationPercent))
                        .font(.vnDisplay(size: 9, weight: .regular))
                        .foregroundColor(.vnTextSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "ds.moon.a11y_label"), phaseType.localizedName, illuminationPercent))
    }

    private var isFullMoon: Bool {
        lunarDay == 15
    }
}
