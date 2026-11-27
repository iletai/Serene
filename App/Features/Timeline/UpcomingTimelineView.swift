import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarLunar

public struct UpcomingTimelineView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @Environment(AdsManager.self) private var ads: AdsManager?
    @State private var viewModel: UpcomingTimelineViewModel?
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    private var activeViewModel: UpcomingTimelineViewModel {
        if let existing = viewModel { return existing }
        return UpcomingTimelineViewModel(
            reminderRepository: container.reminderRepository,
            scheduleReminderUseCase: container.scheduleReminderUseCase,
            evaluateFeatureGateUseCase: container.evaluateFeatureGateUseCase
        )
    }

    public var body: some View {
        @Bindable var vm = activeViewModel
        ScrollView {
            VStack(alignment: .leading, spacing: VNSpacing.lg) {
                headerSection(vm: vm)
                searchBarSection(vm: vm)
                MemorialFilterPills(
                    selectedTab: $vm.selectedFilter.animation(reduceMotion ? nil : .smooth(duration: 0.3)),
                    countForTab: { tab in
                        vm.reminders.filter { tab.matches(category: $0.category) }.count
                    }
                )
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                contentSection(vm: vm)
            }
            .padding(.top, VNSpacing.sm)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .task {
            if viewModel == nil {
                viewModel = activeViewModel
            }
            await viewModel?.load()
            await viewModel?.observe()
        }
    }

    private func createReminder(vm: UpcomingTimelineViewModel) {
        VNHaptics.impact(.light, enabled: hapticFeedbackEnabled)
        Task {
            switch await vm.createReminderGate() {
            case .allowed: router.present(sheet: .reminderForm(editing: nil, initialDate: nil))
            case .requiresPro: router.present(sheet: .paywall)
            }
        }
    }

    private func edit(_ reminder: ReminderEvent) {
        VNHaptics.impact(.light, enabled: hapticFeedbackEnabled)
        router.present(sheet: .reminderForm(editing: reminder, initialDate: nil))
    }

    private func showRitual(_ reminder: ReminderEvent) {
        VNHaptics.impact(.light, enabled: hapticFeedbackEnabled)
        router.present(sheet: .ritual(title: reminder.title))
    }

    // MARK: - Header

    private func headerSection(vm: UpcomingTimelineViewModel) -> some View {
        HStack(alignment: .center, spacing: VNSpacing.md) {
            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text("timeline.eyebrow_range")
                    .font(.vnDisplay(.caption2, weight: .semibold))
                    .tracking(0.9)
                    .foregroundColor(.vnAccentSky)

                Text("timeline.page_title")
                    .font(.vnDisplay(.largeTitle, weight: .heavy))
                    .foregroundColor(.vnTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
            }

            Spacer(minLength: 0)

            Button {
                createReminder(vm: vm)
            } label: {
                Image(systemName: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.vnAccentSky)
                    .frame(width: VNSize.iconButton, height: VNSize.iconButton)
                    .background(Color.vnBackgroundSecondary, in: Circle())
                    .overlay(Circle().stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline))
                    .frame(minWidth: VNSize.minTapTarget, minHeight: VNSize.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("timeline.add_new")
        }
        .padding(.horizontal, VNSpacing.screenMargin)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    // MARK: - Search Bar

    private func searchBarSection(vm: UpcomingTimelineViewModel) -> some View {
        @Bindable var boundVM = vm
        return HStack(spacing: VNSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.vnTextSecondary)
                .font(.subheadline)
                .accessibilityHidden(true)

            TextField("timeline.search_placeholder", text: $boundVM.searchQuery)
                .font(.vnDisplay(.subheadline))

            if !vm.searchQuery.isEmpty {
                Button {
                    vm.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.vnTextTertiary)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .frame(minWidth: VNSize.minTapTarget, minHeight: VNSize.minTapTarget)
                .contentShape(Rectangle())
                .accessibilityLabel("timeline.clear_search_accessibility")
            }
        }
        .padding(.horizontal, VNSpacing.md)
        .frame(minHeight: VNSize.minTapTarget)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.small, style: .continuous)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
        .padding(.horizontal, VNSpacing.screenMargin)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    // MARK: - Content

    @ViewBuilder
    private func contentSection(vm: UpcomingTimelineViewModel) -> some View {
        if vm.filteredReminders.isEmpty {
            VNEmptyState(
                icon: "flame.fill",
                title: String(localized: "timeline.empty_title"),
                quote: String(localized: "timeline.empty_quote"),
                ctaLabel: String(localized: "timeline.empty_cta_add"),
                ctaIcon: "plus.circle.fill",
                onCTA: { createReminder(vm: vm) }
            )
            .padding(.horizontal, VNSpacing.screenMargin)
        } else {
            VStack(alignment: .leading, spacing: VNSpacing.sectionGap) {
                ForEach(Array(vm.sections.enumerated()), id: \.element.id) { index, section in
                    TimelineMonthSectionView(
                        section: section,
                        onEdit: edit,
                        onViewRitual: showRitual,
                        onDelete: { vm.delete($0) }
                    )

                    // Free-tier native ad sits after the first month section.
                    if index == 0, ads?.canShowAds == true {
                        NativeAdCard()
                    }
                }
            }
            .padding(.horizontal, VNSpacing.screenMargin)
        }
    }
}
