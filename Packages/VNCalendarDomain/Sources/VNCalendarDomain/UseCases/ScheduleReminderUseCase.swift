import Foundation

public enum ScheduleReminderError: Error, Sendable, Equatable {
    case freeTierLimitReached
}

public final class ScheduleReminderUseCase: Sendable {
    private let reminderRepository: ReminderRepositoryProtocol
    private let subscriptionRepository: SubscriptionRepositoryProtocol

    public init(
        reminderRepository: ReminderRepositoryProtocol,
        subscriptionRepository: SubscriptionRepositoryProtocol
    ) {
        self.reminderRepository = reminderRepository
        self.subscriptionRepository = subscriptionRepository
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
    }

    public func execute(delete id: UUID) async throws {
        try await reminderRepository.deleteReminder(by: id)
    }
}
