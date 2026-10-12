import XCTest
@testable import VNCalendarDomain
import VNCalendarLunar

final class MockReminderRepository: ReminderRepositoryProtocol, @unchecked Sendable {
    var reminders: [ReminderEvent] = []

    func fetchAllReminders() async throws -> [ReminderEvent] {
        reminders
    }

    func fetchReminders(forMonth month: Int, isLunar: Bool) async throws -> [ReminderEvent] {
        reminders.filter { r in
            (r.dateType == .lunar) == isLunar && r.month == month
        }
    }

    func getReminder(by id: UUID) async throws -> ReminderEvent? {
        reminders.first { $0.id == id }
    }

    func saveReminder(_ reminder: ReminderEvent) async throws {
        if let idx = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[idx] = reminder
        } else {
            reminders.append(reminder)
        }
    }

    func deleteReminder(by id: UUID) async throws {
        reminders.removeAll { $0.id == id }
    }

    func observeReminders() -> AsyncStream<[ReminderEvent]> {
        AsyncStream { continuation in
            continuation.yield(self.reminders)
        }
    }
}

final class MockHolidayRepository: HolidayRepositoryProtocol, @unchecked Sendable {
    var holidays: [Holiday] = [
        Holiday(
            id: "tet-nguyen-dan",
            title: "Tết Nguyên Đán",
            calendarType: .lunar,
            day: 1,
            month: 1,
            isNationalHoliday: true,
            isTraditionHoliday: true,
            summary: "Tết Cổ Truyền"
        )
    ]

    func getHolidays() async throws -> [Holiday] {
        holidays
    }

    func getHolidays(month: Int, isLunar: Bool) async throws -> [Holiday] {
        holidays.filter { $0.month == month && ($0.calendarType == .lunar) == isLunar }
    }

    func getHoliday(by id: String) async throws -> Holiday? {
        holidays.first { $0.id == id }
    }

    func synchronizeRemoteContent() async throws {}
}

final class MockSubscriptionRepository: SubscriptionRepositoryProtocol, @unchecked Sendable {
    var isPro: Bool = false

    func isFeatureUnlocked(_ feature: AppFeature) async -> Bool {
        isPro
    }

    func observeSubscriptionStatus() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            continuation.yield(self.isPro)
        }
    }
}

final class DomainTests: XCTestCase {
    func testFeatureGateLimit() async throws {
        let reminderRepo = MockReminderRepository()
        let subRepo = MockSubscriptionRepository()
        let useCase = EvaluateFeatureGateUseCase(subscriptionRepository: subRepo, reminderRepository: reminderRepo)

        // Free tier with 4 items: can add
        for i in 1...4 {
            try await reminderRepo.saveReminder(ReminderEvent(title: "Giỗ \(i)", day: i, month: 1))
        }
        let canAdd4 = try await useCase.canAddReminder()
        XCTAssertTrue(canAdd4)

        // Free tier with 5 items: blocked
        try await reminderRepo.saveReminder(ReminderEvent(title: "Giỗ 5", day: 5, month: 1))
        let canAdd5 = try await useCase.canAddReminder()
        XCTAssertFalse(canAdd5)

        // Upgrade to Pro: can add unlimited
        subRepo.isPro = true
        let canAddPro = try await useCase.canAddReminder()
        XCTAssertTrue(canAddPro)
    }

    func testGetMonthCalendarUseCase() async throws {
        let reminderRepo = MockReminderRepository()
        let holidayRepo = MockHolidayRepository()
        let useCase = GetMonthCalendarUseCase(reminderRepository: reminderRepo, holidayRepository: holidayRepo)

        // 21/01/1985 is Lunar 01/01/1985 (Tết Nguyên Đán)
        let solarDate = SolarDate(day: 21, month: 1, year: 1985)
        let details = try await useCase.execute(solarDate: solarDate)

        XCTAssertEqual(details.lunarDate.day, 1)
        XCTAssertEqual(details.lunarDate.month, 1)
        XCTAssertFalse(details.holidays.isEmpty)
        XCTAssertEqual(details.holidays.first?.title, "Tết Nguyên Đán")
    }

    func testNaturalSearchUseCase() async throws {
        let reminderRepo = MockReminderRepository()
        let holidayRepo = MockHolidayRepository()
        try await reminderRepo.saveReminder(ReminderEvent(title: "Giỗ Cụ Cố", day: 15, month: 8))

        let useCase = NaturalSearchUseCase(reminderRepository: reminderRepo, holidayRepository: holidayRepo)
        let results = try await useCase.execute(query: "Giỗ")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Giỗ Cụ Cố")
    }
}
