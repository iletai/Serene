import SwiftUI
import StoreKit
import VNCalendarDesignSystem
import VNCalendarData
import VNCalendarDomain

public struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(AppContainer.self) private var container
    @State private var viewModel: PaywallViewModel?
    @State private var legalLinksService = LegalLinksService.shared

    public init() {}

    private var activeViewModel: PaywallViewModel {
        if let existing = viewModel { return existing }
        return PaywallViewModel(subscriptionManager: container.subscriptionManager)
    }

    public var body: some View {
        @Bindable var vm = activeViewModel
        NavigationStack {
            ScrollView {
                VStack(spacing: VNSpacing.xl) {
                    hero
                    featureList
                    productSelector(vm: vm)

                    if let pending = vm.pendingNotice {
                        Text(pending)
                            .font(.vnCaption1)
                            .foregroundColor(.vnTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, VNSpacing.lg)
                    }

                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.vnCaption1)
                            .foregroundColor(.vnStatusError)
                            .padding(.horizontal, VNSpacing.lg)
                    }

                    purchaseCTA(vm: vm)
                    restoreButton(vm: vm)
                    legalLinks
                }
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel == nil {
                    viewModel = activeViewModel
                }
                await legalLinksService.refresh()
            }
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
                                .background(Color.vnBackgroundSecondary)
                                .clipShape(Circle())
                        }
                    )
                    .accessibilityLabel("Đóng bảng nâng cấp")
                }
            }
        }
    }

    // MARK: - Subviews

    private var hero: some View {
        VStack(spacing: VNSpacing.md) {
            VNSealBadge.gio(size: .large)
                .padding(.top, VNSpacing.xl)

            Text("paywall.title")
                .font(.vnTitleHero)
                .foregroundColor(.vnAccentDeepPrimary)

            Text("paywall.subtitle")
                .font(.vnBody)
                .foregroundColor(.vnTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, VNSpacing.xl)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: VNSpacing.md) {
            featureRow(icon: "checkmark", title: "paywall.feature.unlimited_reminders")
            featureRow(icon: "checkmark", title: "paywall.feature.cloudkit_sync")
            featureRow(icon: "checkmark", title: "paywall.feature.heritage_mode")
            featureRow(icon: "checkmark", title: "paywall.feature.pro_widgets")
            featureRow(icon: "checkmark", title: "paywall.feature.ics_export")
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

    @ViewBuilder
    private func productSelector(vm: PaywallViewModel) -> some View {
        VStack(spacing: VNSpacing.sm) {
            if vm.products.isEmpty {
                if vm.isLoading {
                    ProgressView()
                    Text("paywall.loading")
                        .font(.vnFootnote)
                        .foregroundColor(.vnTextSecondary)
                } else {
                    Text("paywall.load_error")
                        .font(.vnFootnote)
                        .foregroundColor(.vnStatusError)
                    Button("paywall.retry") {
                        Task { await vm.loadProducts() }
                    }
                    .font(.vnFootnote)
                    .foregroundColor(.vnAccentImperialGold)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
            } else {
                ForEach(vm.products, id: \.id) { product in
                    productCard(product: product, vm: vm)
                }
            }
        }
        .padding(.horizontal, VNSpacing.xl)
    }

    private func purchaseCTA(vm: PaywallViewModel) -> some View {
        Button(
            action: {
                vm.purchase { dismiss() }
            },
            label: {
                HStack {
                    if vm.isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .vnOnAccent))
                            .accessibilityLabel("Đang xử lý thanh toán")
                    } else {
                        Text(ctaButtonTitle(vm: vm))
                            .font(.vnHeadline)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, VNSpacing.lg)
                .background(Color.vnAccentHeritageRed)
                .foregroundColor(.vnOnAccent)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
            }
        )
        .disabled(vm.isPurchasing || vm.products.isEmpty)
        .padding(.horizontal, VNSpacing.xl)
    }

    private func restoreButton(vm: PaywallViewModel) -> some View {
        Button("paywall.restore") {
            vm.restorePurchases { dismiss() }
        }
        .font(.vnFootnote)
        .foregroundColor(.vnTextSecondary)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .padding(.bottom, VNSpacing.md)
    }

    private var legalLinks: some View {
        HStack(spacing: VNSpacing.lg) {
            legalLink(title: "paywall.terms", url: legalLinksService.termsOfUseURL)
            legalLink(title: "paywall.privacy", url: legalLinksService.privacyPolicyURL)
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

    private func productCard(product: Product, vm: PaywallViewModel) -> some View {
        let isSelected = (vm.selectedProductID == product.id)
        return Button(
            action: { vm.selectedProductID = product.id },
            label: {
                HStack {
                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        HStack {
                            Text(product.displayName)
                                .font(.vnHeadline)
                                .foregroundColor(.vnTextPrimary)
                            if hasFreeTrial(product) {
                                Text("paywall.trial_badge")
                                    .font(.vnCaption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, VNSpacing.xs)
                                    .padding(.vertical, VNSpacing.space2)
                                    .background(Color.vnAccentHeritageRed)
                                    .foregroundColor(.vnOnAccent)
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

    private func ctaButtonTitle(vm: PaywallViewModel) -> LocalizedStringKey {
        if let product = vm.products.first(where: { $0.id == vm.selectedProductID }),
           hasFreeTrial(product) {
            return "paywall.cta_start_trial"
        }
        return "paywall.cta_subscribe"
    }

    private func hasFreeTrial(_ product: Product) -> Bool {
        product.subscription?.introductoryOffer?.paymentMode == .freeTrial
    }
}
