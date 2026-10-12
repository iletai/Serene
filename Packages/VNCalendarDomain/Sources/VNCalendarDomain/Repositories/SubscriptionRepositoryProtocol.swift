import Foundation

public protocol SubscriptionRepositoryProtocol: Sendable {
    func isFeatureUnlocked(_ feature: AppFeature) async -> Bool
    func observeSubscriptionStatus() -> AsyncStream<Bool>
}
