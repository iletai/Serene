import Foundation

public final class EvaluateFeatureGateUseCase: Sendable {
    private let subscriptionRepository: SubscriptionRepositoryProtocol
    private let reminderRepository: ReminderRepositoryProtocol

    public init(
        subscriptionRepository: SubscriptionRepositoryProtocol,
        reminderRepository: ReminderRepositoryProtocol
    ) {
        self.subscriptionRepository = subscriptionRepository
        self.reminderRepository = reminderRepository
    }

    public func canAddReminder() async throws -> Bool {
        let isPro = await subscriptionRepository.isFeatureUnlocked(.unlimitedReminders)
        if isPro { return true }
        let currentReminders = try await reminderRepository.fetchAllReminders()
        return FeatureGateRule.canCreateReminder(currentCount: currentReminders.count, isPro: isPro)
    }

    public func isFeatureAvailable(_ feature: AppFeature) async -> Bool {
        await subscriptionRepository.isFeatureUnlocked(feature)
    }
}
