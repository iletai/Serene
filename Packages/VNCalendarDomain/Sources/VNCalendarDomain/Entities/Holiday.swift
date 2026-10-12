import Foundation

public struct Holiday: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let title: String
    public let calendarType: CalendarDateType
    public let day: Int
    public let month: Int
    public let isNationalHoliday: Bool
    public let isTraditionHoliday: Bool
    public let summary: String
    public let customs: String?
    public let taboos: String?
    public let rituals: String?
    public let updatedAt: Date

    public init(
        id: String,
        title: String,
        calendarType: CalendarDateType,
        day: Int,
        month: Int,
        isNationalHoliday: Bool = false,
        isTraditionHoliday: Bool = false,
        summary: String,
        customs: String? = nil,
        taboos: String? = nil,
        rituals: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.calendarType = calendarType
        self.day = day
        self.month = month
        self.isNationalHoliday = isNationalHoliday
        self.isTraditionHoliday = isTraditionHoliday
        self.summary = summary
        self.customs = customs
        self.taboos = taboos
        self.rituals = rituals
        self.updatedAt = updatedAt
    }
}
