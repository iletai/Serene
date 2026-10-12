import Foundation
import VNCalendarLunar

public struct DayCalendarDetails: Sendable {
    public let solarDate: SolarDate
    public let lunarDate: LunarDate
    public let canChi: FullCanChi
    public let solarTerm: SolarTerm
    public let holidays: [Holiday]
    public let reminders: [ReminderEvent]

    public init(
        solarDate: SolarDate,
        lunarDate: LunarDate,
        canChi: FullCanChi,
        solarTerm: SolarTerm,
        holidays: [Holiday],
        reminders: [ReminderEvent]
    ) {
        self.solarDate = solarDate
        self.lunarDate = lunarDate
        self.canChi = canChi
        self.solarTerm = solarTerm
        self.holidays = holidays
        self.reminders = reminders
    }
}

public final class GetMonthCalendarUseCase: Sendable {
    private let reminderRepository: ReminderRepositoryProtocol
    private let holidayRepository: HolidayRepositoryProtocol
    private let lunarEngine: LunarAstronomicalEngine

    public init(
        reminderRepository: ReminderRepositoryProtocol,
        holidayRepository: HolidayRepositoryProtocol,
        lunarEngine: LunarAstronomicalEngine = .shared
    ) {
        self.reminderRepository = reminderRepository
        self.holidayRepository = holidayRepository
        self.lunarEngine = lunarEngine
    }

    public func execute(solarDate: SolarDate) async throws -> DayCalendarDetails {
        let lunarDate = lunarEngine.convertToLunar(from: solarDate)
        let canChi = lunarEngine.computeCanChi(for: solarDate)
        let jd = AstronomicalMath.julianDay(from: solarDate)
        let term = AstronomicalMath.solarTerm(at: jd)

        async let allHolidays = holidayRepository.getHolidays()
        async let allReminders = reminderRepository.fetchAllReminders()

        let (holidays, reminders) = try await (allHolidays, allReminders)

        let matchingHolidays = holidays.filter { h in
            if h.calendarType == .solar {
                return h.day == solarDate.day && h.month == solarDate.month
            } else {
                // Leap-month memorials must not match the regular month.
                return h.day == lunarDate.day && h.month == lunarDate.month
            }
        }

        let matchingReminders = reminders.filter { r in
            if r.dateType == .solar {
                return r.day == solarDate.day && r.month == solarDate.month
            } else {
                return r.day == lunarDate.day
                    && r.month == lunarDate.month
                    && r.isLeapMonth == lunarDate.isLeapMonth
            }
        }

        return DayCalendarDetails(
            solarDate: solarDate,
            lunarDate: lunarDate,
            canChi: canChi,
            solarTerm: term,
            holidays: matchingHolidays,
            reminders: matchingReminders
        )
    }
}
