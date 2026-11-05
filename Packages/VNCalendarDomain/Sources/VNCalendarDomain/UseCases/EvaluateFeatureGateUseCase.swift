import Foundation

public final class EvaluateFeatureGateUseCase: Sendable {
    private let subscriptionRepository: SubscriptionRepositoryProtocol
    private let reminderRepository: ReminderRepositoryProtocol
    private let bonusSlots: @Sendable () -> Int

    public init(
        subscriptionRepository: SubscriptionRepositoryProtocol,
        reminderRepository: ReminderRepositoryProtocol,
        bonusSlots: @escaping @Sendable () -> Int = { 0 }
    ) {
        self.subscriptionRepository = subscriptionRepository
        self.reminderRepository = reminderRepository
        self.bonusSlots = bonusSlots
    }

    public func canAddReminder() async throws -> Bool {
        let isPro = await subscriptionRepository.isFeatureUnlocked(.unlimitedReminders)
        if isPro { return true }
        let currentReminders = try await reminderRepository.fetchAllReminders()
        return FeatureGateRule.canCreateReminder(
            currentCount: currentReminders.count,
            isPro: isPro,
            bonusSlots: bonusSlots()
        )
    }

    public func isFeatureAvailable(_ feature: AppFeature) async -> Bool {
        await subscriptionRepository.isFeatureUnlocked(feature)
    }
}
