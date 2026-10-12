import SwiftUI
import StoreKit
import VNCalendarDesignSystem

public struct PaywallView: View {
    private static let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
    // swiftlint:disable:next todo
    // TODO: wire real privacy + ToS URLs before App Store submission (Guideline 3.1.2)
    private static let privacyPolicyURL: URL? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProductID: String = ProductID.yearly
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VNSpacing.xl) {
                    hero
                    featureList
                    productSelector

                    if let error = errorMessage {
                        Text(error)
                            .font(.vnCaption1)
                            .foregroundColor(.vnStatusError)
                            .padding(.horizontal, VNSpacing.lg)
                    }

                    purchaseCTA
                    restoreButton
                    legalLinks
                }
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.vnBackgroundPrimary.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        action: { dismiss() },
                        label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.vnTextPrimary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Color.vnBackgroundSecondary,
                                    in: RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                                        .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.regular)
                                )
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                    )
                    .accessibilityLabel("Đóng")
                }
            }
        }
    }

    // Header Heritage Hero
    private var hero: some View {
        VStack(spacing: VNSpacing.sm) {
            // Ceremonial crest: gold crown over cinnabar seal (Ấn Triện)
            VStack(spacing: VNSpacing.sm) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.vnAccentImperialGold)
                    .padding(.top, VNSpacing.xl)

                VNSealBadge(
                    text: "AN NIÊN",
                    shape: .square,
                    color: .custom(
                        background: Color.vnSurfaceElevated,
                        foreground: Color.vnAccentDeepPrimary,
                        border: Color.vnAccentHeritageRed
                    ),
                    size: .large
                )
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Ấn triện An Niên")

            Text("paywall.hero_title")
                .font(.vnDisplayLarge)
                .foregroundColor(.vnTextPrimary)

            Text("paywall.hero_subtitle")
                .font(.vnBody)
                .multilineTextAlignment(.center)
                .foregroundColor(.vnTextSecondary)
                .padding(.horizontal, VNSpacing.xl)
        }
    }

    // Features List
    private var featureList: some View {
        VStack(alignment: .leading, spacing: VNSpacing.md) {
            featureRow(icon: "bell.badge.fill", title: "paywall.unlimited_reminders")
            featureRow(icon: "icloud.fill", title: "paywall.cloudkit_sync")
            featureRow(icon: "person.3.sequence.fill", title: "paywall.genealogy_mode")
            featureRow(icon: "square.grid.2x2.fill", title: "paywall.lockscreen_widgets")
        }
        .padding(VNSpacing.xl)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.regular)
        )
        .padding(.horizontal, VNSpacing.xl)
    }

    // Products Selector
    @ViewBuilder
    private var productSelector: some View {
        VStack(spacing: VNSpacing.sm) {
            if subscriptionManager.products.isEmpty {
                if subscriptionManager.isLoading {
                    ProgressView()
                    Text("paywall.loading")
                        .font(.vnFootnote)
                        .foregroundColor(.vnTextSecondary)
                } else {
                    Text("paywall.load_error")
                        .font(.vnFootnote)
                        .foregroundColor(.vnStatusError)
                    Button("paywall.retry") {
                        Task { await subscriptionManager.loadProducts() }
                    }
                    .font(.vnFootnote)
                    .foregroundColor(.vnAccentImperialGold)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
            } else {
                ForEach(subscriptionManager.products, id: \.id) { product in
                    productCard(product: product)
                }
            }
        }
        .padding(.horizontal, VNSpacing.xl)
    }

    // Main Action CTA Button
    private var purchaseCTA: some View {
        Button(
            action: handlePurchase,
            label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .accessibilityLabel("Đang xử lý thanh toán")
                    } else {
                        Text(ctaButtonTitle)
                            .font(.vnHeadline)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, VNSpacing.lg)
                .background(Color.vnAccentDeepPrimary)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small, style: .continuous))
            }
        )
        .disabled(isPurchasing || subscriptionManager.products.isEmpty)
        .padding(.horizontal, VNSpacing.xl)
    }

    private var restoreButton: some View {
        Button("paywall.restore") {
            Task {
                do {
                    try await subscriptionManager.restorePurchases()
                    if subscriptionManager.entitlement.isPro {
                        dismiss()
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .font(.vnFootnote)
        .foregroundColor(.vnTextSecondary)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .padding(.bottom, VNSpacing.md)
    }

    // Required by App Review Guideline 3.1.2
    private var legalLinks: some View {
        HStack(spacing: VNSpacing.lg) {
            legalLink(title: "paywall.terms", url: Self.termsOfUseURL)
            legalLink(title: "paywall.privacy", url: Self.privacyPolicyURL)
        }
        .padding(.bottom, VNSpacing.xxl)
    }

    private func legalLink(title: LocalizedStringKey, url: URL?) -> some View {
        Button(title) {
            guard let url else { return }
            openURL(url)
        }
        .font(.vnFootnote)
        .foregroundColor(.vnTextSecondary)
        .disabled(url == nil)
    }

    private func featureRow(icon: String, title: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: VNSpacing.md) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.vnOnGoldContainer)
                .accessibilityHidden(true)
                .frame(width: 22, height: 22)
                .background(Color.vnGoldContainer.opacity(0.5))
                .clipShape(Circle())

            Text(title)
                .font(.vnHeadline)
                .foregroundColor(.vnTextPrimary)
        }
    }

    private func productCard(product: Product) -> some View {
        let isSelected = (selectedProductID == product.id)
        return Button(
            action: { selectedProductID = product.id },
            label: {
                HStack {
                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        HStack {
                            Text(product.displayName)
                                .font(.vnHeadline)
                                .foregroundColor(.vnTextPrimary)
                            if product.id == ProductID.yearly {
                                Text("paywall.trial_badge")
                                    .font(.vnCaption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, VNSpacing.xs)
                                    .padding(.vertical, VNSpacing.space2)
                                    .background(Color.vnAccentHeritageRed)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(product.description)
                            .font(.vnCaption2)
                            .foregroundColor(.vnTextSecondary)
                    }
                    Spacer()
                    Text(product.displayPrice)
                        .font(.vnHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .vnAccentHeritageRed : .vnTextPrimary)
                }
                .padding(VNSpacing.xl)
                .background(isSelected ? Color.vnAccentRedSurface : Color.vnBackgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                        .stroke(
                            isSelected ? Color.vnAccentHeritageRed : Color.vnAccentImperialGold.opacity(0.28),
                            lineWidth: isSelected ? VNBorderWidth.active : VNBorderWidth.regular
                        )
                )
            }
        )
        .buttonStyle(PlainButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var ctaButtonTitle: LocalizedStringKey {
        if selectedProductID == ProductID.yearly {
            return "paywall.cta_start_trial"
        }
        return "paywall.title"
    }

    private func handlePurchase() {
        guard let product = subscriptionManager.products.first(where: { $0.id == selectedProductID }) else {
            errorMessage = String(localized: "paywall.load_error")
            return
        }
        isPurchasing = true
        errorMessage = nil

        Task {
            defer { isPurchasing = false }
            do {
                _ = try await subscriptionManager.purchase(product)
                if subscriptionManager.entitlement.isPro {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
