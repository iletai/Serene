import Foundation
import os
import VNCalendarDomain
import VNCalendarLunar

public final class VNMonthLunarCache: @unchecked Sendable {
    public static let shared = VNMonthLunarCache()

    private var unfairLock = os_unfair_lock_s()
    private var cache: [Int: VNCalendarDayModel] = [:]
    private let calendar: Calendar

    public init() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        self.calendar = cal
    }

    @inline(__always)
    public func dayModel(for key: DateKey) -> VNCalendarDayModel? {
        os_unfair_lock_lock(&unfairLock)
        let model = cache[key.rawValue]
        os_unfair_lock_unlock(&unfairLock)
        return model
    }

    public func batchInsert(_ items: [DateKey: VNCalendarDayModel]) {
        os_unfair_lock_lock(&unfairLock)
        for (k, v) in items {
            cache[k.rawValue] = v
        }
        os_unfair_lock_unlock(&unfairLock)
    }

    public func removeAll() {
        os_unfair_lock_lock(&unfairLock)
        cache.removeAll()
        os_unfair_lock_unlock(&unfairLock)
    }

    public func precomputeMonthWindow(around centerDate: Date, reminders: [ReminderEvent] = []) {
        for offset in -1...1 {
            if let monthDate = calendar.date(byAdding: .month, value: offset, to: centerDate) {
                computeMonth42Cells(for: monthDate, reminders: reminders)
            }
        }
    }

    public func computeMonth42Cells(for monthDate: Date, reminders: [ReminderEvent] = []) {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else { return }
        let firstOfMonth = monthInterval.start

        // 1 = Sunday, 2 = Monday, ... 7 = Saturday
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        // Monday first: Monday -> offset 0, Sunday -> offset 6
        let mondayOffset = (weekday == 1) ? 6 : (weekday - 2)

        guard let gridStartDate = calendar.date(byAdding: .day, value: -mondayOffset, to: firstOfMonth) else { return }

        var calculatedCells: [DateKey: VNCalendarDayModel] = [:]
        var currentDate = gridStartDate
        let todayKey = DateKey(date: Date(), calendar: calendar)
        let targetMonthNumber = calendar.component(.month, from: monthDate)

        for _ in 0..<42 {
            let key = DateKey(date: currentDate, calendar: calendar)
            calculatedCells[key] = buildDayModel(
                for: currentDate,
                key: key,
                targetMonth: targetMonthNumber,
                todayKey: todayKey,
                reminders: reminders
            )
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }

        batchInsert(calculatedCells)
    }

    public func computeWeekDays(around date: Date, reminders: [ReminderEvent] = []) -> [VNCalendarDayModel] {
        let weekday = calendar.component(.weekday, from: date)
        let mondayOffset = (weekday == 1) ? 6 : (weekday - 2)
        guard let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: date) else { return [] }

        var days: [VNCalendarDayModel] = []
        var currentDate = monday
        let todayKey = DateKey(date: Date(), calendar: calendar)
        let targetMonthNumber = calendar.component(.month, from: date)

        for _ in 0..<7 {
            let key = DateKey(date: currentDate, calendar: calendar)
            if let cached = dayModel(for: key) {
                days.append(cached)
            } else {
                let computed = buildDayModel(
                    for: currentDate,
                    key: key,
                    targetMonth: targetMonthNumber,
                    todayKey: todayKey,
                    reminders: reminders
                )
                batchInsert([key: computed])
                days.append(computed)
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }

        return days
    }

    public func computeYearMonths(for year: Int, reminders: [ReminderEvent] = []) -> [VNYearMonthModel] {
        var months: [VNYearMonthModel] = []

        for month in 1...12 {
            var comp = DateComponents()
            comp.year = year
            comp.month = month
            comp.day = 1
            guard let monthDate = calendar.date(from: comp) else { continue }

            computeMonth42Cells(for: monthDate, reminders: reminders)

            guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else { continue }
            let firstOfMonth = monthInterval.start
            let weekday = calendar.component(.weekday, from: firstOfMonth)
            let mondayOffset = (weekday == 1) ? 6 : (weekday - 2)
            guard let gridStartDate = calendar.date(byAdding: .day, value: -mondayOffset, to: firstOfMonth) else { continue }

            var monthDays: [VNCalendarDayModel] = []
            var currentDate = gridStartDate
            for _ in 0..<42 {
                let key = DateKey(date: currentDate, calendar: calendar)
                if let model = dayModel(for: key) {
                    monthDays.append(model)
                }
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDay
            }

            months.append(VNYearMonthModel(
                month: month,
                year: year,
                monthName: "Tháng \(month)",
                days: monthDays
            ))
        }

        return months
    }

    public func buildDayModel(
        for date: Date,
        key: DateKey,
        targetMonth: Int,
        todayKey: DateKey,
        reminders: [ReminderEvent]
    ) -> VNCalendarDayModel {
        let solar = SolarDate(day: key.day, month: key.month, year: key.year)
        let jd = AstronomicalMath.julianDay(from: solar)
        let term = AstronomicalMath.solarTerm(at: jd)
        let lunar = LunarAstronomicalEngine.shared.convertToLunar(from: solar)
        let astro = computeDayAstrology(jd: jd, lunar: lunar)

        let nextSolar = AstronomicalMath.solarDate(from: jd + 1)
        let nextLunar = LunarAstronomicalEngine.shared.convertToLunar(from: nextSolar)
        let isLastLunarDay = (lunar.day == 29 && nextLunar.day == 1) || (lunar.day == 30)

        let matchingAnniversaries = filterAnniversaries(
            reminders: reminders,
            key: key,
            lunar: lunar,
            isLastLunarDay: isLastLunarDay
        )

        let isFirstDay = (lunar.day == 1)
        let isFullMoon = (lunar.day == 15)

        return VNCalendarDayModel(
            dateKey: key,
            solarDate: date,
            solarDay: key.day,
            solarMonth: key.month,
            solarYear: key.year,
            weekdayName: fullWeekdayString(from: date),
            lunarDay: lunar.day,
            lunarMonth: lunar.month,
            lunarYear: lunar.year,
            isLeapMonth: lunar.isLeapMonth,
            lunarDayText: isFirstDay ? "1/\(lunar.month)" : "\(lunar.day)",
            lunarMonthName: lunarMonthName(for: lunar.month),
            lunarYearCanChi: astro.yearCanChi,
            lunarDayCanChi: astro.dayCanChiStr,
            lunarMonthCanChi: astro.monthCanChi,
            lunarDayStem: astro.dayStem,
            lunarDayBranch: astro.dayBranch,
            solarTermName: term.isMajorTerm ? term.vietnameseName : nil,
            lunarOfficer: astro.officer,
            zodiacStar: astro.star,
            auspiciousHours: astro.auspiciousHours,
            joyGodDirection: astro.dayStem.joyGodDirection.rawValue,
            wealthGodDirection: astro.dayStem.wealthGodDirection.rawValue,
            suitableActivities: astro.officer.suitableActivities,
            tabooActivities: astro.officer.tabooActivities,
            folkQuote: VNFolkQuotes.quote(for: key),
            isFirstDayOfLunarMonth: isFirstDay,
            isFullMoonDay: isFullMoon,
            isAuspiciousDay: astro.star.isAuspicious,
            isToday: (key.rawValue == todayKey.rawValue),
            isCurrentMonth: (key.month == targetMonth),
            anniversaries: matchingAnniversaries,
            hasAncestorDeathAnniversary: matchingAnniversaries.contains(where: \.isAncestorDeath),
            hasFestival: isFirstDay || isFullMoon
        )
    }

    private struct DayAstroData {
        let dayStem: HeavenlyStem
        let dayBranch: EarthlyBranch
        let dayCanChiStr: String
        let monthCanChi: String
        let yearCanChi: String
        let officer: LunarOfficer
        let star: ZodiacStar
        let auspiciousHours: [EarthlyBranch]
    }

    private func computeDayAstrology(jd: Int, lunar: LunarDate) -> DayAstroData {
        let dayStem = HeavenlyStem(rawValue: (jd + 9) % 10) ?? .giap
        let dayBranch = EarthlyBranch(rawValue: (jd + 1) % 12) ?? .ty
        let dayCanChiStr = "\(dayStem.vietnameseName) \(dayBranch.vietnameseName)"
        let yearStem = HeavenlyStem(rawValue: (lunar.year + 6) % 10) ?? .giap
        let monthCanChi = CanChiPair.month(forLunarMonth: lunar.month, yearStem: yearStem).description
        let monthBranchIndex = (lunar.month + 1) % 12
        let monthBranch = EarthlyBranch(rawValue: monthBranchIndex) ?? .dan
        let officer = LunarOfficer.officer(monthBranch: monthBranch, dayBranch: dayBranch)
        let star = ZodiacStar.star(monthBranch: monthBranch, dayBranch: dayBranch)
        let auspiciousHours = EarthlyBranch.auspiciousHours(for: dayBranch)
        let yearCanChi = CanChiPair.year(for: lunar.year).description

        return DayAstroData(
            dayStem: dayStem,
            dayBranch: dayBranch,
            dayCanChiStr: dayCanChiStr,
            monthCanChi: monthCanChi,
            yearCanChi: yearCanChi,
            officer: officer,
            star: star,
            auspiciousHours: auspiciousHours
        )
    }

    private func filterAnniversaries(
        reminders: [ReminderEvent],
        key: DateKey,
        lunar: LunarDate,
        isLastLunarDay: Bool
    ) -> [AnniversaryDisplayItem] {
        reminders.filter { item in
            if item.dateType == .lunar {
                if item.month == lunar.month, item.isLeapMonth == lunar.isLeapMonth {
                    if item.day == lunar.day { return true }
                    if item.day == 30 && lunar.day == 29 && isLastLunarDay { return true }
                }
                return false
            } else {
                return item.day == key.day && item.month == key.month
            }
        }.map { item in
            AnniversaryDisplayItem(
                id: item.id,
                title: item.title,
                isLunar: (item.dateType == .lunar),
                isAncestorDeath: (item.category == .deathAnniversary || item.category == .ancestral)
            )
        }
    }

    @inline(__always)
    private func fullWeekdayString(from date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        switch weekday {
        case 2: return "Thứ Hai"
        case 3: return "Thứ Ba"
        case 4: return "Thứ Tư"
        case 5: return "Thứ Năm"
        case 6: return "Thứ Sáu"
        case 7: return "Thứ Bảy"
        case 1: return "Chủ Nhật"
        default: return "Thứ Hai"
        }
    }

    @inline(__always)
    private func lunarMonthName(for month: Int) -> String {
        let names = [
            "Tháng Giêng", "Tháng Hai", "Tháng Ba", "Tháng Tư",
            "Tháng Năm", "Tháng Sáu", "Tháng Bảy", "Tháng Tám",
            "Tháng Chín", "Tháng Mười", "Tháng Một", "Tháng Chạp"
        ]
        guard month >= 1, month <= 12 else { return "Tháng \(month)" }
        return names[month - 1]
    }
}
