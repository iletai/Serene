import Foundation

public protocol NotificationScheduling: Sendable {
    func pruneAndSchedule(reminders: [ReminderEvent]) async throws
}
