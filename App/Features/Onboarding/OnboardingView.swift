import SwiftUI
import VNCalendarDesignSystem

/// First-launch walkthrough (prototype `onb-*`): three intro pages, then a preferences page.
struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: OnboardingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: 0) {
            skipBar
            // Native paging gives the swipe gesture; `push` easing and Reduce Motion are applied below.
            TabView(selection: $viewModel.index) {
                OnboardingIntroPage(
                    season: .autumn, title: String(localized: "onboarding.page1.title"), message: String(localized: "onboarding.page1.body")
                ) { OnboardingMoonArt() }
                    .tag(0)
                OnboardingIntroPage(
                    season: .spring, title: String(localized: "onboarding.page2.title"), message: String(localized: "onboarding.page2.body")
                ) { OnboardingBlocArt() }
                    .tag(1)
                OnboardingIntroPage(
                    season: .summer, title: String(localized: "onboarding.page3.title"), message: String(localized: "onboarding.page3.body")
                ) { OnboardingReminderArt() }
                    .tag(2)
                OnboardingPreferencesPage().tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : VNMotion.Easing.push, value: viewModel.index)
            footer
        }
        .padding(.bottom, VNSpacing.sm)
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        // Prototype `.onb.is-leaving`: fade out and grow 3% (opacity only under Reduce Motion).
        .opacity(viewModel.isLeaving ? 0 : 1)
        .scaleEffect(viewModel.isLeaving && !reduceMotion ? 1.03 : 1)
        .animation(.easeOut(duration: 0.3), value: viewModel.isLeaving)
        .vnSelectionFeedback(trigger: viewModel.index)
    }

    private var skipBar: some View {
        HStack {
            Spacer()
            Button(String(localized: "onboarding.skip")) { finish() }
                .font(.vnBody)
                .foregroundStyle(Color.vnAccentHeritageRed)
                .padding(.horizontal, VNSpacing.lg)
                .frame(minHeight: VNSize.minTapTarget)
                .opacity(viewModel.isLastPage ? 0 : 1)
                .disabled(viewModel.isLastPage)
                .accessibilityHidden(viewModel.isLastPage)
        }
    }

    private var footer: some View {
        VStack(spacing: VNSpacing.md) {
            OnboardingDots(count: OnboardingViewModel.pageCount, current: viewModel.index) { viewModel.go(to: $0) }
            footerActions
        }
        .padding(.horizontal, VNSpacing.screenMargin)
        .padding(.top, VNSpacing.sm)
    }

    @ViewBuilder
    private var footerActions: some View {
        if viewModel.isLastPage {
            VNButton(String(localized: "onboarding.finish"), size: .large, isFullWidth: true) { finish() }
        } else if viewModel.index == OnboardingViewModel.notificationPageIndex, !viewModel.notificationsEnabled {
            VNButton(String(localized: "onboarding.notify.enable"), icon: "bell.fill", size: .large, isFullWidth: true) {
                Task { await viewModel.enableNotifications() }
            }
            VNButton(String(localized: "onboarding.notify.later"), variant: .tertiary, size: .large, isFullWidth: true) {
                viewModel.next()
            }
        } else {
            if viewModel.index == OnboardingViewModel.notificationPageIndex {
                Label(String(localized: "onboarding.notify.enabled"), systemImage: "checkmark")
                    .font(.vnCallout.weight(.semibold))
                    .foregroundStyle(Color.vnAccentJade)
                    .frame(minHeight: VNSize.buttonLarge)
            }
            VNButton(String(localized: "onboarding.continue"), size: .large, isFullWidth: true) { viewModel.next() }
        }
    }

    private func finish() {
        Task { await viewModel.finish(animated: !reduceMotion) }
    }
}

/// Pages 1-3: artwork, title and one supporting line, centred.
private struct OnboardingIntroPage<Art: View>: View {
    let season: ArtSeason
    let title: String
    let message: String
    @ViewBuilder let art: Art

    var body: some View {
        ScrollView {
            VStack(spacing: VNSpacing.lg) {
                ArtPanel(season: season, height: 260) { art }
                    .padding(.horizontal, VNSpacing.screenMargin)
                    .accessibilityHidden(true)
                OnboardingHeading(title: title, message: message)
            }
            .frame(maxWidth: .infinity)
            .containerRelativeFrame(.vertical, alignment: .center)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

/// Prototype `.onb-dot`: 8pt dots, the current one stretches to a 20pt pill.
private struct OnboardingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let count: Int
    let current: Int
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { page in
                Button { onSelect(page) } label: {
                    Capsule()
                        .fill(page == current ? Color.vnAccentHeritageRed : Color.vnBorderStrong)
                        .frame(width: page == current ? 20 : 8, height: 8)
                        .frame(width: 28, height: VNSize.minTapTarget)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(format: String(localized: "onboarding.step_a11y"), page + 1, count))
                .accessibilityAddTraits(page == current ? .isSelected : [])
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: current)
    }
}
