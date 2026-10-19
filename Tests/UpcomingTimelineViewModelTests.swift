import XCTest
import VNCalendarDomain
@testable import AnNien

@MainActor
final class UpcomingTimelineViewModelTests: XCTestCase {
    final class MockReminderRepo: ReminderRepositoryProtocol, @unchecked Sendable {
        var items: [ReminderEvent] = []
        func fetchAllReminders() async throws -> [ReminderEvent] { items }
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

    func testFilterAndSearch() async {
        let repo = MockReminderRepo()
        let sub = MockSubRepo()
        let schedule = ScheduleReminderUseCase(reminderRepository: repo, subscriptionRepository: sub)
        let gate = EvaluateFeatureGateUseCase(subscriptionRepository: sub, reminderRepository: repo)

        repo.items = [
            ReminderEvent(title: "Giỗ Cụ", category: .deathAnniversary, day: 1, month: 1),
            ReminderEvent(title: "Sinh nhật Bé", category: .birthday, day: 2, month: 2)
        ]

        let vm = UpcomingTimelineViewModel(
            reminderRepository: repo,
            scheduleReminderUseCase: schedule,
            evaluateFeatureGateUseCase: gate
        )
        await vm.load()

        XCTAssertEqual(vm.reminders.count, 2)
        vm.selectedFilter = .deathAnniversary
        XCTAssertEqual(vm.filteredReminders.count, 1)
        XCTAssertEqual(vm.filteredReminders.first?.title, "Giỗ Cụ")

        vm.selectedFilter = .all
        vm.searchQuery = "Sinh"
        XCTAssertEqual(vm.filteredReminders.count, 1)
        XCTAssertEqual(vm.filteredReminders.first?.title, "Sinh nhật Bé")
    }
}
