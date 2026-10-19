import Foundation
import VNCalendarLunar

public struct DateKey: Hashable, Sendable, Comparable, CustomStringConvertible {
    public let rawValue: Int // Format: YYYYMMDD (e.g. 20260929)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(year: Int, month: Int, day: Int) {
        self.rawValue = year * 10000 + month * 100 + day
    }

    public init(date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) {
        var cal = calendar
        cal.timeZone = VNTime.vietnam
        let c = cal.dateComponents([.year, .month, .day], from: date)
        self.init(year: c.year ?? 2026, month: c.month ?? 1, day: c.day ?? 1)
    }

    public init(solarDate: SolarDate) {
        self.init(year: solarDate.year, month: solarDate.month, day: solarDate.day)
    }

    public var year: Int {
        rawValue / 10000
    }

    public var month: Int {
        (rawValue % 10000) / 100
    }

    public var day: Int {
        rawValue % 100
    }

    public var toSolarDate: SolarDate {
        SolarDate(day: day, month: month, year: year)
    }

    public var toDate: Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        return cal.date(from: components)
    }

    public static func < (lhs: DateKey, rhs: DateKey) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        "\(rawValue)"
    }
}
