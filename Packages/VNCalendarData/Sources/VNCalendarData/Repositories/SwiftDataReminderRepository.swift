import Foundation
import SwiftData
import Combine
import VNCalendarDomain

public final class SwiftDataReminderRepository: ReminderRepositoryProtocol, Sendable {
    private let dataActor: ReminderDataActor
    private let stateActor: RepositoryStateActor

    private actor RepositoryStateActor {
        var subscribers: [UUID: AsyncStream<[ReminderEvent]>.Continuation] = [:]

        func addSubscriber(id: UUID, continuation: AsyncStream<[ReminderEvent]>.Continuation) {
            subscribers[id] = continuation
        }

        func removeSubscriber(id: UUID) {
            subscribers.removeValue(forKey: id)
        }

        func broadcast(items: [ReminderEvent]) {
            for (_, continuation) in subscribers {
                continuation.yield(items)
            }
        }
    }

    public init(modelContainer: ModelContainer) {
        let actor = ReminderDataActor(modelContainer: modelContainer)
        self.dataActor = actor
        self.stateActor = RepositoryStateActor()
    }

    public func fetchAllReminders() async throws -> [ReminderEvent] {
        try await dataActor.fetchAllReminders()
    }

    public func fetchReminders(forMonth month: Int, isLunar: Bool) async throws -> [ReminderEvent] {
        try await dataActor.fetchReminders(forMonth: month, isLunar: isLunar)
    }

    public func getReminder(by id: UUID) async throws -> ReminderEvent? {
        try await dataActor.getReminder(by: id)
    }

    public func saveReminder(_ reminder: ReminderEvent) async throws {
        try await dataActor.saveReminder(reminder)
        await notifySubscribers()
    }

    public func deleteReminder(by id: UUID) async throws {
        try await dataActor.deleteReminder(by: id)
        await notifySubscribers()
    }

    public func observeReminders() -> AsyncStream<[ReminderEvent]> {
        AsyncStream { continuation in
            let subId = UUID()
            Task {
                await self.stateActor.addSubscriber(id: subId, continuation: continuation)
                if let initial = try? await self.dataActor.fetchAllReminders() {
                    continuation.yield(initial)
                }
            }

            continuation.onTermination = { [stateActor = self.stateActor] _ in
                Task {
                    await stateActor.removeSubscriber(id: subId)
                }
            }
        }
    }

    private func notifySubscribers() async {
        do {
            let items = try await dataActor.fetchAllReminders()
            await stateActor.broadcast(items: items)
        } catch {
            // Ignore fetch error
        }
    }
}
