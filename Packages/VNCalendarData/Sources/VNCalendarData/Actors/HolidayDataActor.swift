import Foundation
import SwiftData
import VNCalendarDomain

@ModelActor
public actor HolidayDataActor {
    public func fetchAllHolidays() throws -> [Holiday] {
        let descriptor = FetchDescriptor<HolidayEntity>(
            sortBy: [SortDescriptor(\.month), SortDescriptor(\.day)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    public func fetchHolidays(month: Int, isLunar: Bool) throws -> [Holiday] {
        let calendarType = isLunar ? "lunar" : "solar"
        let descriptor = FetchDescriptor<HolidayEntity>(
            predicate: #Predicate<HolidayEntity> {
                $0.month == month && $0.calendarTypeRawValue == calendarType
            },
            sortBy: [SortDescriptor(\.day)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    public func getHoliday(by id: String) throws -> Holiday? {
        let targetId = id
        let descriptor = FetchDescriptor<HolidayEntity>(
            predicate: #Predicate<HolidayEntity> { $0.id == targetId }
        )
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    public func upsertHolidays(_ holidays: [Holiday]) throws {
        for item in holidays {
            let targetId = item.id
            let descriptor = FetchDescriptor<HolidayEntity>(
                predicate: #Predicate<HolidayEntity> { $0.id == targetId }
            )

            if let existing = try modelContext.fetch(descriptor).first {
                existing.title = item.title
                existing.calendarTypeRawValue = item.calendarType.rawValue
                existing.day = item.day
                existing.month = item.month
                existing.isNationalHoliday = item.isNationalHoliday
                existing.isTraditionHoliday = item.isTraditionHoliday
                existing.summary = item.summary
                existing.customs = item.customs
                existing.taboos = item.taboos
                existing.rituals = item.rituals
                existing.updatedAt = item.updatedAt
            } else {
                let newEntity = HolidayEntity(
                    id: item.id,
                    title: item.title,
                    calendarTypeRawValue: item.calendarType.rawValue,
                    day: item.day,
                    month: item.month,
                    isNationalHoliday: item.isNationalHoliday,
                    isTraditionHoliday: item.isTraditionHoliday,
                    summary: item.summary,
                    customs: item.customs,
                    taboos: item.taboos,
                    rituals: item.rituals,
                    updatedAt: item.updatedAt
                )
                modelContext.insert(newEntity)
            }
        }
        try modelContext.save()
    }

    public func hasHolidays() throws -> Bool {
        let descriptor = FetchDescriptor<HolidayEntity>()
        return try modelContext.fetchCount(descriptor) > 0
    }

    public func holidayCount() throws -> Int {
        let descriptor = FetchDescriptor<HolidayEntity>()
        return try modelContext.fetchCount(descriptor)
    }
}
