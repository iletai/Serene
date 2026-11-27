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
    @Environment(AdsManager.self) private var ads: AdsManager?
    @State private var isWatchingAd = false
    @State private var adUnavailable = false
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
                    watchAdButton
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
        VStack(spacing: VNSpacing.sm) {
            Image(systemName: "crown.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.vnAccentImperialGold)
                .vnCrownShine()
                .padding(.bottom, VNSpacing.xs)
                .accessibilityHidden(true)

            Text("paywall.title")
                .font(.vnTitleHero)
                .foregroundColor(.vnOnAccent)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)

            Text("paywall.subtitle")
                .font(.vnBody)
                .foregroundColor(.vnOnAccent.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, VNSpacing.screenMargin)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VNSpacing.xxl)
        .background(
            LinearGradient(
                colors: [Color.vnAccentHeritageRed, Color.vnAccentDeepPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
        .padding(.horizontal, VNSpacing.screenMargin)
        .padding(.top, VNSpacing.md)
        .vnRise(distance: 18)
    }

    private struct Benefit: Identifiable {
        let id: String
        let icon: String
        let tint: Color
        let title: String
        let subtitle: String
    }

    private var benefits: [Benefit] {
        [
            Benefit(
                id: "ads",
                icon: "megaphone.slash.fill",
                tint: .vnAccentHeritageRed,
                title: String(localized: "paywall.benefit.ads.title"),
                subtitle: String(localized: "paywall.benefit.ads.desc")
            ),
            Benefit(
                id: "reminders",
                icon: "infinity",
                tint: .vnAccentSky,
                title: String(localized: "paywall.benefit.reminders.title"),
                subtitle: String(localized: "paywall.benefit.reminders.desc")
            ),
            Benefit(
                id: "icloud",
                icon: "icloud.fill",
                tint: .vnAccentJade,
                title: String(localized: "paywall.benefit.icloud.title"),
                subtitle: String(localized: "paywall.benefit.icloud.desc")
            ),
            Benefit(
                id: "widgets",
                icon: "rectangle.on.rectangle",
                tint: .vnAccentGoldText,
                title: String(localized: "paywall.benefit.widgets.title"),
                subtitle: String(localized: "paywall.benefit.widgets.desc")
            ),
            Benefit(
                id: "heritage",
                icon: "person.3.sequence.fill",
                tint: .vnTextTertiary,
                title: String(localized: "paywall.benefit.heritage.title"),
                subtitle: String(localized: "paywall.benefit.heritage.desc")
            )
        ]
    }

    private var featureList: some View {
        VNGroupCard {
            ForEach(Array(benefits.enumerated()), id: \.element.id) { index, benefit in
                if index > 0 {
                    VNRowDivider(leadingInset: VNSpacing.cardPadding)
                }
                VNListRow(
                    icon: benefit.icon,
                    iconTint: benefit.tint,
                    title: benefit.title,
                    subtitle: benefit.subtitle,
                    showsChevron: false
                )
                .vnRise(index: index, baseDelay: 0.12, stagger: 0.06)
            }
        }
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

    @ViewBuilder
    private var watchAdButton: some View {
        if let ads, ads.canShowAds, !RewardedSlotStore.isAtCap {
            VStack(spacing: VNSpacing.xs) {
                Button("paywall.watch_ad") {
                    isWatchingAd = true
                    adUnavailable = false
                    Task {
                        let earned = await ads.showRewardedForBonusSlot()
                        isWatchingAd = false
                        if earned { router.dismissModals() } else { adUnavailable = true }
                    }
                }
                .font(.vnFootnote)
                .foregroundColor(.vnAccentGoldText)
                .frame(minHeight: VNSize.minTapTarget)
                .contentShape(Rectangle())
                .disabled(isWatchingAd)

                if adUnavailable {
                    Text("paywall.watch_ad_unavailable")
                        .font(.vnCaption1)
                        .foregroundColor(.vnTextSecondary)
                }
            }
        }
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

    private func productCard(product: Product, vm: PaywallViewModel) -> some View {
        let isSelected = (vm.selectedProductID == product.id)
        return Button(
            action: { vm.selectedProductID = product.id },
            label: {
                HStack(spacing: VNSpacing.md) {
                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        HStack {
                            Text(product.displayName)
                                .font(.vnHeadline)
                                .fontWeight(.bold)
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
                            .lineLimit(2)
                    }
                    Spacer(minLength: VNSpacing.sm)
                    Text(product.displayPrice)
                        .font(.vnHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .vnAccentGoldText : .vnTextPrimary)
                    radioIndicator(isSelected)
                }
                .padding(VNSpacing.cardPadding)
                .background(isSelected ? Color.vnAccentGoldSurface : Color.vnBackgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                        .stroke(
                            isSelected ? Color.vnAccentGoldText : Color.vnBorderSubtle,
                            lineWidth: isSelected ? VNBorderWidth.active : VNBorderWidth.regular
                        )
                )
                .overlay(alignment: .topTrailing) {
                    if isPopularPlan(product) {
                        popularBadge
                            .offset(x: -VNSpacing.md, y: -10)
                    }
                }
                .scaleEffect(isSelected && !reduceMotion ? 1.015 : 1)
                .animation(reduceMotion ? nil : .bouncy(duration: 0.35, extraBounce: 0.1), value: isSelected)
            }
        )
        .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
        .sensoryFeedback(.selection, trigger: isSelected) { _, new in new }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func radioIndicator(_ isSelected: Bool) -> some View {
        Circle()
            .strokeBorder(
                isSelected ? Color.vnAccentGoldText : Color.vnTextTertiary,
                lineWidth: isSelected ? 6 : VNBorderWidth.regular
            )
            .frame(width: 22, height: 22)
            .accessibilityHidden(true)
    }

    private var popularBadge: some View {
        Text("paywall.plan.popular")
            .font(.vnCaption2)
            .fontWeight(.bold)
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundColor(.vnOnGoldContainer)
            .padding(.horizontal, VNSpacing.sm)
            .padding(.vertical, VNSpacing.space2)
            .background(Color.vnAccentImperialGold)
            .clipShape(Capsule())
    }

    private func isPopularPlan(_ product: Product) -> Bool {
        product.subscription?.subscriptionPeriod.unit == .year
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
