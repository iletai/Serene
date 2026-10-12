import Foundation

public protocol ReminderRepositoryProtocol: Sendable {
    func fetchAllReminders() async throws -> [ReminderEvent]
    func fetchReminders(forMonth month: Int, isLunar: Bool) async throws -> [ReminderEvent]
    func getReminder(by id: UUID) async throws -> ReminderEvent?
    func saveReminder(_ reminder: ReminderEvent) async throws
    func deleteReminder(by id: UUID) async throws
    func observeReminders() -> AsyncStream<[ReminderEvent]>
}
