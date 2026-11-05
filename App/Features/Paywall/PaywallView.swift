import SwiftUI
import StoreKit
import VNCalendarDesignSystem
import VNCalendarData
import VNCalendarDomain

public struct PaywallView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppContainer.self) private var container
    @State private var viewModel: PaywallViewModel?
    @State private var legalLinksService = LegalLinksService.shared
    @ScaledMetric(relativeTo: .caption2) private var badgeSize: CGFloat = VNSize.iconBadge

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

                    VStack(spacing: VNSpacing.sm) {
                        if let pending = vm.pendingNotice {
                            Text(pending)
                                .font(.vnCaption1)
                                .foregroundColor(.vnTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, VNSpacing.lg)
                                .transition(.opacity)
                        }
    
                        if let error = vm.errorMessage {
                            Text(error)
                                .font(.vnCaption1)
                                .foregroundColor(.vnStatusError)
                                .padding(.horizontal, VNSpacing.lg)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    }
                    .animation(reduceMotion ? nil : .smooth, value: vm.errorMessage)
                    .animation(reduceMotion ? nil : .smooth, value: vm.pendingNotice)

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
                    VNDismissButton { router.dismissModals() }
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
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)

            Text("paywall.subtitle")
                .font(.vnBody)
                .foregroundColor(.vnTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, VNSpacing.screenMargin)
        }
    }

    private static let featureKeys: [LocalizedStringKey] = [
        "paywall.feature.unlimited_reminders",
        "paywall.feature.cloudkit_sync",
        "paywall.feature.heritage_mode",
        "paywall.feature.pro_widgets",
        "paywall.feature.ics_export"
    ]

    private var featureList: some View {
        VStack(alignment: .leading, spacing: VNSpacing.md) {
            ForEach(Array(Self.featureKeys.enumerated()), id: \.offset) { index, key in
                featureRow(icon: "checkmark", title: key)
                    .modifier(PaywallRowAppear(index: index, reduceMotion: reduceMotion))
            }
        }
        .padding(VNSpacing.cardPadding)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.regular)
        )
        .padding(.horizontal, VNSpacing.screenMargin)
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
                    .foregroundColor(.vnAccentGoldText)
                    .frame(minHeight: VNSize.minTapTarget)
                    .contentShape(Rectangle())
                }
            } else {
                ForEach(vm.products, id: \.id) { product in
                    productCard(product: product, vm: vm)
                }
            }
        }
        .padding(.horizontal, VNSpacing.screenMargin)
    }

    private func purchaseCTA(vm: PaywallViewModel) -> some View {
        Button(
            action: {
                vm.purchase { router.dismissModals() }
            },
            label: {
                HStack {
                    if vm.isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .vnOnAccent))
                            .accessibilityLabel("paywall.a11y_purchasing")
                    } else {
                        Text(ctaButtonTitle(vm: vm))
                            .font(.vnHeadline)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: VNSize.buttonLarge)
                .background(Color.vnAccentHeritageRed)
                .foregroundColor(.vnOnAccent)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small, style: .continuous))
                .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: vm.isPurchasing)
            }
        )
        .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
        .disabled(vm.isPurchasing || vm.products.isEmpty)
        .padding(.horizontal, VNSpacing.screenMargin)
    }

    private func restoreButton(vm: PaywallViewModel) -> some View {
        Button("paywall.restore") {
            vm.restorePurchases { router.dismissModals() }
        }
        .font(.vnFootnote)
        .foregroundColor(.vnTextSecondary)
        .frame(minHeight: VNSize.minTapTarget)
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
        .frame(minHeight: VNSize.minTapTarget)
        .disabled(url == nil)
    }

    private func featureRow(icon: String, title: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: VNSpacing.md) {
            Image(systemName: "checkmark")
                .font(.caption2.weight(.bold))
                .foregroundColor(.vnOnGoldContainer)
                .accessibilityHidden(true)
                .frame(width: badgeSize, height: badgeSize)
                .background(Color.vnGoldContainer.opacity(0.5))
                .clipShape(Circle())

            Text(title)
                .font(.vnHeadline)
                .foregroundColor(.vnTextPrimary)
        }
        .accessibilityElement(children: .combine)
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
                .padding(VNSpacing.cardPadding)
                .background(isSelected ? Color.vnAccentRedSurface : Color.vnBackgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                        .stroke(
                            isSelected ? Color.vnAccentHeritageRed : Color.vnAccentImperialGold.opacity(0.28),
                            lineWidth: isSelected ? VNBorderWidth.active : VNBorderWidth.regular
                        )
                )
                .scaleEffect(isSelected && !reduceMotion ? 1.015 : 1)
                .animation(reduceMotion ? nil : .bouncy(duration: 0.35, extraBounce: 0.1), value: isSelected)
            }
        )
        .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
        .sensoryFeedback(.selection, trigger: isSelected) { _, new in new }
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

private struct PaywallRowAppear: ViewModifier {
    let index: Int
    let reduceMotion: Bool
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared || reduceMotion ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 8)
            .onAppear {
                withAnimation(.smooth(duration: 0.4).delay(0.15 + Double(index) * 0.06)) { appeared = true }
            }
    }
}
