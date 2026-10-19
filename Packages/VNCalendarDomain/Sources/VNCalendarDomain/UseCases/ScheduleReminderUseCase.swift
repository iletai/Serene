import Foundation

public enum ScheduleReminderError: Error, Sendable, Equatable {
    case freeTierLimitReached
}

public final class ScheduleReminderUseCase: Sendable {
    private let reminderRepository: ReminderRepositoryProtocol
    private let subscriptionRepository: SubscriptionRepositoryProtocol
    private let notificationScheduler: NotificationScheduling?

    public init(
        reminderRepository: ReminderRepositoryProtocol,
        subscriptionRepository: SubscriptionRepositoryProtocol,
        notificationScheduler: NotificationScheduling? = nil
    ) {
        self.reminderRepository = reminderRepository
        self.subscriptionRepository = subscriptionRepository
        self.notificationScheduler = notificationScheduler
    }

    public func execute(save reminder: ReminderEvent) async throws {
        // Gate only new reminders; edits to existing ones are always allowed.
        if try await reminderRepository.getReminder(by: reminder.id) == nil {
            let isPro = await subscriptionRepository.isFeatureUnlocked(.unlimitedReminders)
            if !isPro {
                let count = try await reminderRepository.fetchAllReminders().count
                guard count < FeatureGateRule.freeMaxReminders else {
                    throw ScheduleReminderError.freeTierLimitReached
                }
            }
        }
        try await reminderRepository.saveReminder(reminder)
        await pruneNotifications()
    }

    public func execute(delete id: UUID) async throws {
        try await reminderRepository.deleteReminder(by: id)
        await pruneNotifications()
    }

    private func pruneNotifications() async {
        guard let scheduler = notificationScheduler,
              let all = try? await reminderRepository.fetchAllReminders() else { return }
        try? await scheduler.pruneAndSchedule(reminders: all)
    }
}
