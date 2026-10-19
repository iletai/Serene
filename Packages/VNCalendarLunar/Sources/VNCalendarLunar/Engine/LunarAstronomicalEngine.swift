import Foundation

public actor LunarAstronomicalEngine {
    public static let shared = LunarAstronomicalEngine()

    public init() {}

    /// Chuyển đổi Dương Lịch -> Âm Lịch (Chuẩn GMT+7 theo giải thuật GS. Hồ Ngọc Đức)
    nonisolated public func convertToLunar(from solar: SolarDate, timeZoneOffset: Double = 7.0) -> LunarDate {
        let dayNumber = AstronomicalMath.julianDay(from: solar)
        var k = Int(floor((Double(dayNumber) - 2415021.076998695) / 29.530588853))
        var monthStart = AstronomicalMath.newMoonJulianDay(k: k + 1, timeZoneOffset: timeZoneOffset)

        if monthStart > dayNumber {
            monthStart = AstronomicalMath.newMoonJulianDay(k: k, timeZoneOffset: timeZoneOffset)
        } else {
            k += 1
        }

        // Tìm tháng 11 năm trước và năm nay
        var a11 = getLunarMonth11(year: solar.year - 1, timeZoneOffset: timeZoneOffset)
        var b11 = getLunarMonth11(year: solar.year, timeZoneOffset: timeZoneOffset)
        var lunarYear = solar.year

        if a11 >= monthStart {
            lunarYear = solar.year - 1
            a11 = getLunarMonth11(year: solar.year - 2, timeZoneOffset: timeZoneOffset)
            b11 = getLunarMonth11(year: solar.year - 1, timeZoneOffset: timeZoneOffset)
        } else if b11 <= monthStart {
            lunarYear = solar.year + 1
            a11 = getLunarMonth11(year: solar.year, timeZoneOffset: timeZoneOffset)
            b11 = getLunarMonth11(year: solar.year + 1, timeZoneOffset: timeZoneOffset)
        }

        let lunarDay = dayNumber - monthStart + 1
        let diff = Int(floor(Double(monthStart - a11) / 29.0))
        var isLeap = false
        var lunarMonth = diff + 11

        if b11 - a11 > 365 {
            let leapMonthDiff = getLeapMonthOffset(a11: a11, timeZoneOffset: timeZoneOffset)
            if diff >= leapMonthDiff {
                lunarMonth = diff + 10
                if diff == leapMonthDiff {
                    isLeap = true
                }
            }
        }

        if lunarMonth > 12 {
            lunarMonth -= 12
        }
        if lunarMonth >= 11 && diff < 4 {
            lunarYear -= 1
        }

        return LunarDate(day: lunarDay, month: lunarMonth, year: lunarYear, isLeapMonth: isLeap)
    }

    /// Chuyển đổi Âm Lịch -> Dương Lịch
    nonisolated public func convertToSolar(from lunar: LunarDate, timeZoneOffset: Double = 7.0) -> SolarDate {
        var a11: Int
        if lunar.month < 11 {
            a11 = getLunarMonth11(year: lunar.year - 1, timeZoneOffset: timeZoneOffset)
        } else {
            a11 = getLunarMonth11(year: lunar.year, timeZoneOffset: timeZoneOffset)
        }

        let b11 = getLunarMonth11(year: (lunar.month < 11 ? lunar.year : lunar.year + 1), timeZoneOffset: timeZoneOffset)
        var off = lunar.month - 11
        if off < 0 {
            off += 12
        }

        if b11 - a11 > 365 {
            let leapOff = getLeapMonthOffset(a11: a11, timeZoneOffset: timeZoneOffset)
            let isLeap = lunar.isLeapMonth
            if isLeap {
                off = leapOff
            } else if off >= leapOff {
                off += 1
            }
        }

        let k = Int(floor((Double(a11) - 2415021.076998695) / 29.530588853 + 0.5))
        let monthStart = AstronomicalMath.newMoonJulianDay(k: k + off, timeZoneOffset: timeZoneOffset)
        let nextMonthStart = AstronomicalMath.newMoonJulianDay(k: k + off + 1, timeZoneOffset: timeZoneOffset)
        let monthLength = nextMonthStart - monthStart

        let validDay = min(lunar.day, monthLength)
        let resultJD = monthStart + validDay - 1
        return AstronomicalMath.solarDate(from: resultJD)
    }

    /// Kiểm tra năm Âm lịch `year` có tháng nhuận đúng số `month` hay không.
    /// Round-trip qua convertToSolar/convertToLunar thay vì lặp lại công thức
    /// thiên văn: hai hàm này đã được kiểm chứng, nên kết quả tự nhất quán.
    nonisolated public func hasLeapMonth(ofLunarYear year: Int, matching month: Int) -> Bool {
        let probe = LunarDate(day: 1, month: month, year: year, isLeapMonth: true)
        let solar = convertToSolar(from: probe)
        let back = convertToLunar(from: solar)
        return back.isLeapMonth && back.month == month && back.year == year
    }

    /// Tính toán Can Chi cho ngày Dương Lịch
    nonisolated public func computeCanChi(for solar: SolarDate, hourIndex: Int = 0) -> FullCanChi {
        let jd = AstronomicalMath.julianDay(from: solar)
        let lunar = convertToLunar(from: solar)

        let yearStem = HeavenlyStem(rawValue: (lunar.year + 6) % 10) ?? .giap
        let yearBranch = EarthlyBranch(rawValue: (lunar.year + 8) % 12) ?? .ty
        let yearPair = CanChiPair(stem: yearStem, branch: yearBranch)

        let dayStem = HeavenlyStem(rawValue: (jd + 9) % 10) ?? .giap
        let dayBranch = EarthlyBranch(rawValue: (jd + 1) % 12) ?? .ty
        let dayPair = CanChiPair(stem: dayStem, branch: dayBranch)

        let monthStemIndex = (yearStem.rawValue * 2 + lunar.month + 1) % 10
        let monthStem = HeavenlyStem(rawValue: monthStemIndex) ?? .giap
        let monthBranchIndex = (lunar.month + 1) % 12
        let monthBranch = EarthlyBranch(rawValue: monthBranchIndex) ?? .ty
        let monthPair = CanChiPair(stem: monthStem, branch: monthBranch)

        let clampedHour = max(0, min(11, hourIndex))
        let hourStemIndex = (dayStem.rawValue * 2 + clampedHour) % 10
        let hourStem = HeavenlyStem(rawValue: hourStemIndex) ?? .giap
        let hourBranch = EarthlyBranch(rawValue: clampedHour) ?? .ty
        let hourPair = CanChiPair(stem: hourStem, branch: hourBranch)

        return FullCanChi(year: yearPair, month: monthPair, day: dayPair, hour: hourPair)
    }

    // MARK: - Internal Astronomy Helpers

    nonisolated private func getLunarMonth11(year: Int, timeZoneOffset: Double) -> Int {
        let dec31JD = AstronomicalMath.julianDay(from: SolarDate(day: 31, month: 12, year: year))
        let off = dec31JD - 2415021
        let k = Int(floor(Double(off) / 29.530588853))
        var nm = AstronomicalMath.newMoonJulianDay(k: k, timeZoneOffset: timeZoneOffset)
        let sunLong = AstronomicalMath.sunLongitude(at: nm, timeZoneOffset: timeZoneOffset)
        if sunLong >= 270.0 {
            nm = AstronomicalMath.newMoonJulianDay(k: k - 1, timeZoneOffset: timeZoneOffset)
        }
        return nm
    }

    nonisolated private func getLeapMonthOffset(a11: Int, timeZoneOffset: Double) -> Int {
        var k = Int(floor((Double(a11) - 2415021.076998695) / 29.530588853 + 0.5))
        var last = 0
        var i = 1
        let nm = AstronomicalMath.newMoonJulianDay(k: k, timeZoneOffset: timeZoneOffset)
        var arc = AstronomicalMath.sunLongitude(at: nm, timeZoneOffset: timeZoneOffset)

        while true {
            last = Int(floor(arc / 30.0))
            k += 1
            let d = AstronomicalMath.newMoonJulianDay(k: k, timeZoneOffset: timeZoneOffset)
            arc = AstronomicalMath.sunLongitude(at: d, timeZoneOffset: timeZoneOffset)
            let current = Int(floor(arc / 30.0))
            if current == last {
                return i
            }
            i += 1
            if i > 14 {
                break
            }
        }
        return 0
    }
}
