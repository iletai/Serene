import XCTest
import VNCalendarDomain
@testable import AnNien

@MainActor
final class CalendarMainViewModelTests: XCTestCase {
    struct FetchError: Error {}

    final class MockReminderRepo: ReminderRepositoryProtocol, @unchecked Sendable {
        var items: [ReminderEvent] = []
        var shouldThrow = false
        func fetchAllReminders() async throws -> [ReminderEvent] {
            if shouldThrow { throw FetchError() }
            return items
        }
        func fetchReminders(forMonth month: Int, isLunar: Bool) async throws -> [ReminderEvent] {
            items.filter { $0.month == month && ($0.dateType == .lunar) == isLunar }
        }
        func getReminder(by id: UUID) async throws -> ReminderEvent? { items.first { $0.id == id } }
        func saveReminder(_ reminder: ReminderEvent) async throws {
            items.removeAll { $0.id == reminder.id }
            items.append(reminder)
        }
        func deleteReminder(by id: UUID) async throws { items.removeAll { $0.id == id } }
        func observeReminders() -> AsyncStream<[ReminderEvent]> {
            AsyncStream { continuation in continuation.yield(self.items) }
        }
    }

    final class MockSubRepo: SubscriptionRepositoryProtocol, @unchecked Sendable {
        var unlocked = true
        func isFeatureUnlocked(_ feature: AppFeature) async -> Bool { unlocked }
        func observeSubscriptionStatus() -> AsyncStream<Bool> {
            AsyncStream { continuation in continuation.yield(self.unlocked) }
        }
    }

    final class MockHolidayRepo: HolidayRepositoryProtocol, @unchecked Sendable {
        func getHolidays() async throws -> [Holiday] { [] }
        func getHolidays(month: Int, isLunar: Bool) async throws -> [Holiday] { [] }
        func getHoliday(by id: String) async throws -> Holiday? { nil }
        func synchronizeRemoteContent() async throws {}
    }

    private func makeViewModel(repo: MockReminderRepo, sub: MockSubRepo) -> CalendarMainViewModel {
        CalendarMainViewModel(
            getMonthCalendarUseCase: GetMonthCalendarUseCase(reminderRepository: repo, holidayRepository: MockHolidayRepo()),
            reminderRepository: repo,
            evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase(subscriptionRepository: sub, reminderRepository: repo)
        )
    }

    private func reminders(_ count: Int) -> [ReminderEvent] {
        (1...count).map { ReminderEvent(title: "Giỗ \($0)", category: .deathAnniversary, day: $0, month: 1) }
    }

    func testCreateReminderGateAllowsPro() async {
        let repo = MockReminderRepo()
        repo.items = reminders(10)
        let sub = MockSubRepo()
        sub.unlocked = true

        let gate = await makeViewModel(repo: repo, sub: sub).createReminderGate()
        XCTAssertEqual(gate, .allowed)
    }

    func testCreateReminderGateRequiresProWhenFreeOverLimit() async {
        let repo = MockReminderRepo()
        repo.items = reminders(5)
        let sub = MockSubRepo()
        sub.unlocked = false

        let gate = await makeViewModel(repo: repo, sub: sub).createReminderGate()
        XCTAssertEqual(gate, .requiresPro)
    }

    func testCreateReminderGateRequiresProWhenGateThrows() async {
        let repo = MockReminderRepo()
        repo.shouldThrow = true
        let sub = MockSubRepo()
        sub.unlocked = false

        let gate = await makeViewModel(repo: repo, sub: sub).createReminderGate()
        XCTAssertEqual(gate, .requiresPro)
    }
}
