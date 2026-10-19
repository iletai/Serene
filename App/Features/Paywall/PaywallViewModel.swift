import SwiftUI
import Observation
import StoreKit
import VNCalendarData

@Observable
@MainActor
final class PaywallViewModel {
    var selectedProductID: String = ProductID.yearly
    var isPurchasing = false
    var errorMessage: String?
    var pendingNotice: String?

    private let subscriptionManager: SubscriptionManager

    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
    }

    var products: [Product] {
        subscriptionManager.products
    }

    var isLoading: Bool {
        subscriptionManager.isLoading
    }

    var isPro: Bool {
        subscriptionManager.entitlement.isPro
    }

    func loadProducts() async {
        await subscriptionManager.loadProducts()
    }

    func purchase(onSuccess: @escaping () -> Void) {
        guard !isPurchasing else { return }
        guard let product = products.first(where: { $0.id == selectedProductID }) else {
            errorMessage = String(localized: "paywall.load_error")
            return
        }

        isPurchasing = true
        errorMessage = nil
        pendingNotice = nil

        Task {
            defer { isPurchasing = false }
            do {
                _ = try await subscriptionManager.purchase(product)
                if isPro {
                    onSuccess()
                }
            } catch StoreError.pending {
                pendingNotice = String(localized: "paywall.pending")
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func restorePurchases(onSuccess: @escaping () -> Void) {
        guard !isPurchasing else { return }
        isPurchasing = true
        errorMessage = nil

        Task {
            defer { isPurchasing = false }
            do {
                try await subscriptionManager.restorePurchases()
                if isPro {
                    onSuccess()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
