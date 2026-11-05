import Foundation

public enum ScheduleReminderError: Error, Sendable, Equatable {
    case freeTierLimitReached
}

public final class ScheduleReminderUseCase: Sendable {
    private let reminderRepository: ReminderRepositoryProtocol
    private let subscriptionRepository: SubscriptionRepositoryProtocol
    private let notificationScheduler: NotificationScheduling?
    private let bonusSlots: @Sendable () -> Int

    public init(
        reminderRepository: ReminderRepositoryProtocol,
        subscriptionRepository: SubscriptionRepositoryProtocol,
        notificationScheduler: NotificationScheduling? = nil,
        bonusSlots: @escaping @Sendable () -> Int = { 0 }
    ) {
        self.reminderRepository = reminderRepository
        self.subscriptionRepository = subscriptionRepository
        self.notificationScheduler = notificationScheduler
        self.bonusSlots = bonusSlots
    }

    public func execute(save reminder: ReminderEvent) async throws {
        // Gate only new reminders; edits to existing ones are always allowed.
        if try await reminderRepository.getReminder(by: reminder.id) == nil {
            let isPro = await subscriptionRepository.isFeatureUnlocked(.unlimitedReminders)
            if !isPro {
                let count = try await reminderRepository.fetchAllReminders().count
                guard FeatureGateRule.canCreateReminder(currentCount: count, isPro: false, bonusSlots: bonusSlots()) else {
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
