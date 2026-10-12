import Foundation
import SwiftData
import VNCalendarDomain

@Model
public final class HolidayEntity {
    public var id: String = ""
    public var title: String = ""
    public var calendarTypeRawValue: String = "lunar"
    public var day: Int = 1
    public var month: Int = 1
    public var isNationalHoliday = false
    public var isTraditionHoliday = false
    public var summary: String = ""
    public var customs: String?
    public var taboos: String?
    public var rituals: String?
    public var updatedAt = Date()

    public init(
        id: String = "",
        title: String = "",
        calendarTypeRawValue: String = "lunar",
        day: Int = 1,
        month: Int = 1,
        isNationalHoliday: Bool = false,
        isTraditionHoliday: Bool = false,
        summary: String = "",
        customs: String? = nil,
        taboos: String? = nil,
        rituals: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.calendarTypeRawValue = calendarTypeRawValue
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

    public func toDomain() -> Holiday {
        Holiday(
            id: self.id,
            title: self.title,
            calendarType: CalendarDateType(rawValue: self.calendarTypeRawValue) ?? .lunar,
            day: self.day,
            month: self.month,
            isNationalHoliday: self.isNationalHoliday,
            isTraditionHoliday: self.isTraditionHoliday,
            summary: self.summary,
            customs: self.customs,
            taboos: self.taboos,
            rituals: self.rituals,
            updatedAt: self.updatedAt
        )
    }
}
