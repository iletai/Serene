import XCTest
import VNCalendarDomain
import VNCalendarData
@testable import AnNien

@MainActor
final class FamilyHierarchyViewModelTests: XCTestCase {
    // Repeated from UpcomingTimelineViewModelTests on purpose (no shared test helpers).
    final class MockReminderRepo: ReminderRepositoryProtocol, @unchecked Sendable {
        var items: [ReminderEvent] = []
        var fetchError: Error?
        func fetchAllReminders() async throws -> [ReminderEvent] {
            if let fetchError { throw fetchError }
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

    private struct FetchFailed: Error {}

    private func makeViewModel(repo: MockReminderRepo, sub: MockSubRepo) -> FamilyHierarchyViewModel {
        FamilyHierarchyViewModel(
            reminderRepository: repo,
            subscriptionManager: SubscriptionManager.shared,
            evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase(subscriptionRepository: sub, reminderRepository: repo)
        )
    }

    private func reminders(_ count: Int) -> [ReminderEvent] {
        (0..<count).map { ReminderEvent(title: "Giỗ \($0)", category: .deathAnniversary, day: 1, month: 1) }
    }

    func testProUserIsAllowed() async {
        let repo = MockReminderRepo()
        repo.items = reminders(FeatureGateRule.freeMaxReminders + 3)
        let sub = MockSubRepo()
        sub.unlocked = true

        let gate = await makeViewModel(repo: repo, sub: sub).createReminderGate()
        XCTAssertEqual(gate, .allowed)
    }

    func testFreeUserOverLimitRequiresPro() async {
        let repo = MockReminderRepo()
        repo.items = reminders(FeatureGateRule.freeMaxReminders)
        let sub = MockSubRepo()
        sub.unlocked = false

        let gate = await makeViewModel(repo: repo, sub: sub).createReminderGate()
        XCTAssertEqual(gate, .requiresPro)
    }

    func testFreeUserUnderLimitIsAllowed() async {
        let repo = MockReminderRepo()
        repo.items = reminders(FeatureGateRule.freeMaxReminders - 1)
        let sub = MockSubRepo()
        sub.unlocked = false

        let gate = await makeViewModel(repo: repo, sub: sub).createReminderGate()
        XCTAssertEqual(gate, .allowed)
    }

    func testThrowingGateRequiresPro() async {
        let repo = MockReminderRepo()
        repo.fetchError = FetchFailed()
        let sub = MockSubRepo()
        sub.unlocked = false

        let gate = await makeViewModel(repo: repo, sub: sub).createReminderGate()
        XCTAssertEqual(gate, .requiresPro)
    }

    func testObserveRefreshesReminders() async {
        let repo = MockReminderRepo()
        repo.items = reminders(2)
        let viewModel = makeViewModel(repo: repo, sub: MockSubRepo())

        // Mock stream yields once and never finishes, so cancel after the first value lands.
        let task = Task { await viewModel.observe() }
        for _ in 0..<50 where viewModel.reminders.isEmpty { await Task.yield() }
        task.cancel()
        XCTAssertEqual(viewModel.reminders.count, 2)
    }
}
