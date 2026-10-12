import Foundation
import VNCalendarDomain
import VNCalendarLunar

public struct VNYearMonthModel: Identifiable, Sendable, Equatable {
    public var id: Int { month }
    public let month: Int
    public let year: Int
    public let monthName: String
    public let days: [VNCalendarDayModel]

    public init(
        month: Int,
        year: Int,
        monthName: String,
        days: [VNCalendarDayModel]
    ) {
        self.month = month
        self.year = year
        self.monthName = monthName
        self.days = days
    }
}
