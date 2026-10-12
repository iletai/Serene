import WidgetKit
import SwiftUI
import VNCalendarLunar
import VNCalendarDomain
import VNCalendarData

public struct LunarWidgetEntry: TimelineEntry {
    public let date: Date
    public let solarDay: Int
    public let solarMonth: Int
    public let solarYear: Int
    public let weekdayName: String
    public let lunarDay: Int
    public let lunarMonth: Int
    public let lunarDayText: String
    public let lunarMonthText: String
    public let lunarYearCanChi: String
    public let solarTermName: String?
    public let nextMemorialTitle: String?
    public let nextMemorialDaysLeft: Int?

    public init(
        date: Date,
        solarDay: Int,
        solarMonth: Int,
        solarYear: Int,
        weekdayName: String,
        lunarDay: Int,
        lunarMonth: Int,
        lunarDayText: String,
        lunarMonthText: String,
        lunarYearCanChi: String,
        solarTermName: String?,
        nextMemorialTitle: String? = nil,
        nextMemorialDaysLeft: Int? = nil
    ) {
        self.date = date
        self.solarDay = solarDay
        self.solarMonth = solarMonth
        self.solarYear = solarYear
        self.weekdayName = weekdayName
        self.lunarDay = lunarDay
        self.lunarMonth = lunarMonth
        self.lunarDayText = lunarDayText
        self.lunarMonthText = lunarMonthText
        self.lunarYearCanChi = lunarYearCanChi
        self.solarTermName = solarTermName
        self.nextMemorialTitle = nextMemorialTitle
        self.nextMemorialDaysLeft = nextMemorialDaysLeft
    }
}

public struct LunarTimelineProvider: TimelineProvider {
    public typealias Entry = LunarWidgetEntry

    public func placeholder(in context: Context) -> LunarWidgetEntry {
        LunarWidgetEntry(
            date: Date(),
            solarDay: 29,
            solarMonth: 9,
            solarYear: 2026,
            weekdayName: "Thứ Ba",
            lunarDay: 19,
            lunarMonth: 8,
            lunarDayText: "19/8",
            lunarMonthText: "Tháng Tám",
            lunarYearCanChi: "Bính Ngọ",
            solarTermName: "Thu Phân",
            nextMemorialTitle: "Giỗ Cụ Cố",
            nextMemorialDaysLeft: 5
        )
    }

    public func getSnapshot(in context: Context, completion: @escaping (LunarWidgetEntry) -> Void) {
        let entry = makeEntry(for: Date())
        completion(entry)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<LunarWidgetEntry>) -> Void) {
        var entries: [LunarWidgetEntry] = []
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current

        let now = Date()
        for hourOffset in 0..<24 {
            if let entryDate = cal.date(byAdding: .hour, value: hourOffset, to: now) {
                entries.append(makeEntry(for: entryDate))
            }
        }

        let nextUpdate = cal.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }

    private func makeEntry(for date: Date) -> LunarWidgetEntry {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current

        let solar = SolarDate(from: date, calendar: cal)
        let jd = AstronomicalMath.julianDay(from: solar)
        let term = AstronomicalMath.solarTerm(at: jd)
        let lunar = LunarAstronomicalEngine.shared.convertToLunar(from: solar)
        let canChi = LunarAstronomicalEngine.shared.computeCanChi(for: solar)

        let weekdaySymbols = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
        let weekday = cal.component(.weekday, from: date)
        let weekdayName = weekdaySymbols[(weekday - 1) % 7]

        return LunarWidgetEntry(
            date: date,
            solarDay: solar.day,
            solarMonth: solar.month,
            solarYear: solar.year,
            weekdayName: weekdayName,
            lunarDay: lunar.day,
            lunarMonth: lunar.month,
            lunarDayText: "\(lunar.day)/\(lunar.month)",
            lunarMonthText: lunar.monthTitle,
            lunarYearCanChi: canChi.year.description,
            solarTermName: term.isMajorTerm ? term.vietnameseName : nil,
            nextMemorialTitle: nil,
            nextMemorialDaysLeft: nil
        )
    }
}
