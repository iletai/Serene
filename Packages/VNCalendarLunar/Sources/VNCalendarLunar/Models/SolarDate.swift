import Foundation

public struct SolarDate: Hashable, Sendable, Codable, CustomStringConvertible {
    public let day: Int
    public let month: Int
    public let year: Int

    public init(day: Int, month: Int, year: Int) {
        self.day = day
        self.month = month
        self.year = year
    }

    public init(from date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) {
        var cal = calendar
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        let components = cal.dateComponents([.day, .month, .year], from: date)
        self.day = components.day ?? 1
        self.month = components.month ?? 1
        self.year = components.year ?? 2026
    }

    public var description: String {
        String(format: "%02d/%02d/%04d", day, month, year)
    }

    public var date: Date? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return cal.date(from: comps)
    }
}
