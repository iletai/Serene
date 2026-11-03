import XCTest
import VNCalendarDomain
@testable import AnNien

private struct Failure: Error {}

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

    final class ThrowingReminderRepo: ReminderRepositoryProtocol, @unchecked Sendable {
        func fetchAllReminders() async throws -> [ReminderEvent] { throw Failure() }
        func fetchReminders(forMonth month: Int, isLunar: Bool) async throws -> [ReminderEvent] { throw Failure() }
        func getReminder(by id: UUID) async throws -> ReminderEvent? { throw Failure() }
        func saveReminder(_ reminder: ReminderEvent) async throws { throw Failure() }
        func deleteReminder(by id: UUID) async throws { throw Failure() }
        func observeReminders() -> AsyncStream<[ReminderEvent]> { AsyncStream { $0.finish() } }
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

    private func makeViewModel(
        repo: ReminderRepositoryProtocol,
        unlocked: Bool
    ) -> UpcomingTimelineViewModel {
        let sub = MockSubRepo()
        sub.unlocked = unlocked
        return UpcomingTimelineViewModel(
            reminderRepository: repo,
            scheduleReminderUseCase: ScheduleReminderUseCase(reminderRepository: repo, subscriptionRepository: sub),
            evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase(subscriptionRepository: sub, reminderRepository: repo)
        )
    }

    func testCreateReminderGateFreeTierAtLimitRequiresPro() async {
        let repo = MockReminderRepo()
        repo.items = (1...FeatureGateRule.freeMaxReminders).map {
            ReminderEvent(title: "Giỗ \($0)", category: .deathAnniversary, day: $0, month: 1)
        }
        let gate = await makeViewModel(repo: repo, unlocked: false).createReminderGate()
        XCTAssertEqual(gate, .requiresPro)
    }

    func testCreateReminderGateProIsAllowed() async {
        let repo = MockReminderRepo()
        repo.items = (1...FeatureGateRule.freeMaxReminders).map {
            ReminderEvent(title: "Giỗ \($0)", category: .deathAnniversary, day: $0, month: 1)
        }
        let gate = await makeViewModel(repo: repo, unlocked: true).createReminderGate()
        XCTAssertEqual(gate, .allowed)
    }

    func testCreateReminderGateThrowingRepoRequiresPro() async {
        let gate = await makeViewModel(repo: ThrowingReminderRepo(), unlocked: false).createReminderGate()
        XCTAssertEqual(gate, .requiresPro)
    }

    func testObserveRefreshesReminders() async {
        let repo = MockReminderRepo()
        repo.items = [ReminderEvent(title: "Giỗ Ông", category: .deathAnniversary, day: 3, month: 3)]
        let vm = makeViewModel(repo: repo, unlocked: true)
        let task = Task { await vm.observe() }
        for _ in 0..<50 where vm.reminders.isEmpty { await Task.yield() }
        task.cancel()
        XCTAssertEqual(vm.reminders.map(\.title), ["Giỗ Ông"])
    }
}
