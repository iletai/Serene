import Foundation

public struct LunarDate: Hashable, Sendable, Codable, CustomStringConvertible {
    public let day: Int
    public let month: Int
    public let year: Int
    public let isLeapMonth: Bool

    public init(day: Int, month: Int, year: Int, isLeapMonth: Bool = false) {
        self.day = day
        self.month = month
        self.year = year
        self.isLeapMonth = isLeapMonth
    }

    public var formattedDayMonth: String {
        if day == 1 {
            return isLeapMonth ? "1/\(month)N" : "1/\(month)"
        }
        return "\(day)"
    }

    public var monthTitle: String {
        isLeapMonth ? "Tháng \(month) (Nhuận)" : "Tháng \(month)"
    }

    public var description: String {
        isLeapMonth
            ? String(format: "%02d/%02d (Nhuận)/%04d ÂL", day, month, year)
            : String(format: "%02d/%02d/%04d ÂL", day, month, year)
    }
}
