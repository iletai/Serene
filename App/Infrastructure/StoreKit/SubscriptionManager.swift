import Foundation
import StoreKit
import Observation
import OSLog
import VNCalendarDomain

private let logger = Logger(subsystem: "com.iletai.annien", category: "SubscriptionManager")

// Cache lives in the shared App Group so widgets can also read last-known Pro state.
// Key + suite name contract for widget/config agents:
//   suite = AppConfiguration.current.appGroupIdentifier
//   key   = "subscription_entitlement"  (rawValue of ProTierType; absent = free)
private let entitlementCacheKey = "subscription_entitlement"

public enum ProductID {
    public static let monthly = "com.iletai.annien.sub.monthly"
    public static let yearly = "com.iletai.annien.sub.yearly"
    public static let lifetime = "com.iletai.annien.nonconsumable.lifetime"
    public static let all: Set<String> = [monthly, yearly, lifetime]
}

public enum ProTierType: String, Sendable, Equatable {
    case monthly
    case yearly
    case lifetime
}

public enum EntitlementStatus: Sendable, Equatable {
    case free
    case pro(ProTierType)

    public var isPro: Bool {
        if case .pro = self { return true }
        return false
    }
}

public enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound
    case userCancelled
    case pending

    public var errorDescription: String? {
        switch self {
        case .failedVerification: return "Xác thực giao dịch App Store thất bại."
        case .productNotFound: return "Không tìm thấy sản phẩm yêu cầu."
        case .userCancelled: return "Giao dịch đã bị huỷ."
        case .pending: return "Giao dịch đang chờ duyệt (Ask to Buy)."
        }
    }
}

@Observable
@MainActor
public final class SubscriptionManager {
    public static let shared = SubscriptionManager()

    public private(set) var products: [Product] = []
    public private(set) var entitlement: EntitlementStatus = .free
    public private(set) var isLoading = false

    private var transactionListener: Task<Void, Never>?
    private var statusObservers: [UUID: AsyncStream<Bool>.Continuation] = [:]

    public init() {
        // Last-known entitlement from App Group cache so cold launch is not "free"
        // while the StoreKit refresh Task runs. Refreshed online; cache is advisory.
        if let raw = UserDefaults(suiteName: AppConfiguration.current.appGroupIdentifier)?
            .string(forKey: entitlementCacheKey),
           let tier = ProTierType(rawValue: raw) {
            entitlement = .pro(tier)
        }
        self.transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    /// Call from scenePhase .active so entitlement revalidates on foreground.
    public func refreshEntitlements() async {
        await updatePurchasedProducts()
    }

    public func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(for: ProductID.all)
            self.products = fetched.sorted { $0.price < $1.price }
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
        }
    }

    public func purchase(_ product: Product) async throws -> Transaction {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction

        case .userCancelled:
            throw StoreError.userCancelled

        case .pending:
            throw StoreError.pending

        @unknown default:
            throw StoreError.failedVerification
        }
    }

    public func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
    }

    public func updatePurchasedProducts() async {
        var activeTier: EntitlementStatus = .free

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }

            // Apple drops expired/cancelled transactions from currentEntitlements,
            // but re-check here so a stale cache cannot keep Pro offline.
            let isExpired = transaction.expirationDate.map { $0 <= Date() } ?? false
            if transaction.revocationDate == nil, !isExpired {
                switch transaction.productID {
                case ProductID.lifetime:
                    activeTier = .pro(.lifetime)
                case ProductID.yearly:
                    if activeTier != .pro(.lifetime) { activeTier = .pro(.yearly) }
                case ProductID.monthly:
                    if activeTier == .free { activeTier = .pro(.monthly) }
                default:
                    break
                }
            }
        }

        self.entitlement = activeTier
        persistEntitlementCache(activeTier)
        broadcastStatus(activeTier.isPro)
    }

    private func persistEntitlementCache(_ status: EntitlementStatus) {
        guard let defaults = UserDefaults(suiteName: AppConfiguration.current.appGroupIdentifier) else { return }
        if case .pro(let tier) = status {
            defaults.set(tier.rawValue, forKey: entitlementCacheKey)
        } else {
            defaults.removeObject(forKey: entitlementCacheKey)
        }
    }

    private func broadcastStatus(_ isPro: Bool) {
        for continuation in statusObservers.values {
            continuation.yield(isPro)
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    logger.error("Transaction update verification failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // Pure function over StoreKit verification results — safe off the main actor.
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}

extension SubscriptionManager: @preconcurrency SubscriptionRepositoryProtocol {
    public func isFeatureUnlocked(_ feature: AppFeature) async -> Bool {
        // Delegate gating to Domain rule; Pro unlocks all for now, free gates all.
        // Domain agent owns the per-feature switch inside FeatureGateRule.
        FeatureGateRule.isFeatureAvailable(feature, isPro: entitlement.isPro)
    }

    public func observeSubscriptionStatus() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let id = UUID()
            continuation.yield(self.entitlement.isPro)
            self.statusObservers[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.statusObservers.removeValue(forKey: id)
                }
            }
        }
    }
}
