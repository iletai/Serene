import Foundation

public enum LunarPhaseName: String, Sendable, Codable, CaseIterable {
    case newMoon = "Trăng Non"
    case waxingCrescent = "Trăng Lưỡi Liềm Đầu Tháng"
    case firstQuarter = "Trăng Thượng Huyền"
    case waxingGibbous = "Trăng Khuyết Dần Đầy"
    case fullMoon = "Trăng Tròn (Rằm)"
    case waningGibbous = "Trăng Khuyết Dần Vơi"
    case lastQuarter = "Trăng Hạ Huyền"
    case waningCrescent = "Trăng Tàn Cuối Tháng"
}

public struct MoonPhaseInfo: Sendable, Codable, Equatable {
    public let phase: LunarPhaseName
    public let illumination: Double // 0.0 to 1.0
    public let lunarDay: Int

    public init(phase: LunarPhaseName, illumination: Double, lunarDay: Int) {
        self.phase = phase
        self.illumination = max(0.0, min(1.0, illumination))
        self.lunarDay = lunarDay
    }

    public static func compute(for lunarDay: Int) -> MoonPhaseInfo {
        let clampedDay = max(1, min(30, lunarDay))
        let phase: LunarPhaseName
        let illumination: Double

        switch clampedDay {
        case 1:
            phase = .newMoon
            illumination = 0.0
        case 2...6:
            phase = .waxingCrescent
            illumination = Double(clampedDay - 1) / 14.0 * 0.45
        case 7...9:
            phase = .firstQuarter
            illumination = 0.50
        case 10...14:
            phase = .waxingGibbous
            illumination = 0.50 + Double(clampedDay - 9) / 6.0 * 0.45
        case 15:
            phase = .fullMoon
            illumination = 1.0
        case 16...21:
            phase = .waningGibbous
            illumination = 1.0 - Double(clampedDay - 15) / 7.0 * 0.45
        case 22...24:
            phase = .lastQuarter
            illumination = 0.50
        case 25...30:
            phase = .waningCrescent
            illumination = max(0.02, 0.50 - Double(clampedDay - 24) / 6.0 * 0.48)
        default:
            phase = .newMoon
            illumination = 0.0
        }

        return MoonPhaseInfo(phase: phase, illumination: illumination, lunarDay: clampedDay)
    }
}
