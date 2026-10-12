import Foundation
import SwiftData
import VNCalendarDomain
import OSLog

private let logger = Logger(subsystem: "com.iletai.annien", category: "SeedDataLoader")

private struct BundledHolidayDTO: Decodable {
    let id: String
    let title: String
    let calendarType: String
    let day: Int
    let month: Int
    let isNationalHoliday: Bool
    let isTraditionHoliday: Bool
    let summary: String
    let customs: String?
    let taboos: String?
    let rituals: String?
    let updatedAt: String?
}

public enum SeedDataLoader {
    public static func seedInitialHolidaysIfNeeded(
        dataActor: HolidayDataActor,
        bundle: Bundle? = nil
    ) async {
        do {
            if try await dataActor.hasHolidays() { return }

            #if SWIFT_PACKAGE
            let targetBundle = bundle ?? Bundle.module
            #else
            let targetBundle = bundle ?? Bundle.main
            #endif

            guard let fileURL = targetBundle.url(forResource: "bundled_holidays", withExtension: "json") else {
                logger.warning("bundled_holidays.json not found in resources bundle.")
                return
            }

            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let dtos = try decoder.decode([BundledHolidayDTO].self, from: data)

            let domainHolidays = dtos.map { dto in
                Holiday(
                    id: dto.id,
                    title: dto.title,
                    calendarType: CalendarDateType(rawValue: dto.calendarType) ?? .lunar,
                    day: dto.day,
                    month: dto.month,
                    isNationalHoliday: dto.isNationalHoliday,
                    isTraditionHoliday: dto.isTraditionHoliday,
                    summary: dto.summary,
                    customs: dto.customs,
                    taboos: dto.taboos,
                    rituals: dto.rituals,
                    updatedAt: Date()
                )
            }

            try await dataActor.upsertHolidays(domainHolidays)
            logger.info("Successfully seeded \(domainHolidays.count) bundled holidays.")
        } catch {
            logger.error("Failed to seed holidays: \(error.localizedDescription)")
        }
    }
}
