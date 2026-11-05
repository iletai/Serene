import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarKit
import VNCalendarLunar

public struct CalendarMainView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @State private var viewModel: CalendarMainViewModel?

    public init() {}

    private var activeViewModel: CalendarMainViewModel {
        if let existing = viewModel { return existing }
        return CalendarMainViewModel(
            getMonthCalendarUseCase: container.getMonthCalendarUseCase,
            reminderRepository: container.reminderRepository,
            evaluateFeatureGateUseCase: container.evaluateFeatureGateUseCase
        )
    }

    public var body: some View {
        let vm = activeViewModel
        ScrollView {
            VStack(spacing: VNSpacing.lg) {
                // 1. Primary focus: today's date, Can Chi, nearest memorial. Secondary info is collapsed.
                TodayDashboardCard(
                    details: vm.todayDetails,
                    upcomingMemorial: vm.upcomingMemorial,
                    onAddReminder: { presentReminderForm(vm: vm) },
                    onQuickSearch: { router.present(sheet: .search) }
                )
                .padding(.horizontal, VNSpacing.screenMargin)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("today.card")

                // 2. Calendar. Multi-Mode Calendar Container (Nhật Lịch • Tháng • Tuần • Năm).
                // The package fires this only after its own day sheet has finished dismissing.
                VNCalendarContainerView(
                    viewModel: vm.adapterViewModel,
                    onAddReminderForSelectedDate: { presentReminderForm(vm: vm) }
                )
                .background(Color.vnSurfaceElevated.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: VNCard<EmptyView>.defaultCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCard<EmptyView>.defaultCornerRadius)
                        .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.hairline)
                )
                .shadow(
                    color: VNCard<EmptyView>.folioShadow.color,
                    radius: VNCard<EmptyView>.folioShadow.radius,
                    x: VNCard<EmptyView>.folioShadow.x,
                    y: VNCard<EmptyView>.folioShadow.y
                )
                .padding(.horizontal, VNSpacing.screenMargin)
            }
            .padding(.top, VNSpacing.sm)
            .padding(.bottom, VNSpacing.sectionGap)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) {
            topNavigationHeader(vm: vm)
        }
        .task {
            if viewModel == nil {
                viewModel = activeViewModel
            }
            await viewModel?.loadData()
            await viewModel?.observeReminders()
        }
    }

    private func presentReminderForm(vm: CalendarMainViewModel) {
        Task {
            switch await vm.createReminderGate() {
            case .allowed:
                router.present(sheet: .reminderForm(editing: nil, initialDate: vm.adapterViewModel.selectedDate))
            case .requiresPro:
                router.present(sheet: .paywall)
            }
        }
    }

    // MARK: - Top Editorial Header
    private func topNavigationHeader(vm: CalendarMainViewModel) -> some View {
        HStack(alignment: .center, spacing: VNSpacing.sm) {
            headerButton(
                icon: "calendar.badge.clock",
                accessibilityLabel: "Xem hôm nay"
            ) {
                VNHaptics.impact(enabled: hapticFeedbackEnabled)
                vm.adapterViewModel.selectToday()
            }

            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text("AN NIÊN")
                    .font(.system(.headline, design: .serif).weight(.semibold))
                    .foregroundColor(.vnAccentDeepPrimary)

                Text(lunarSubtitle(vm: vm))
                    .font(.caption2.weight(.medium))
                    .tracking(0.66)
                    .foregroundColor(.vnTextSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            yearSwitcherPill(vm: vm)

            headerButton(
                icon: "gearshape",
                accessibilityLabel: "Cài đặt ứng dụng"
            ) {
                VNHaptics.impact(enabled: hapticFeedbackEnabled)
                router.present(sheet: .settings)
            }
        }
        .padding(.horizontal, VNSpacing.screenMargin)
        .padding(.vertical, VNSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.vnBackgroundPrimary.opacity(0.9)
                .background(.ultraThinMaterial)
        )
        .shadow(color: VNShadow.card.color, radius: VNShadow.card.radius, x: VNShadow.card.x, y: VNShadow.card.y)
        // Top-bar chrome caps its growth like system nav bars; content below scales fully.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func yearSwitcherPill(vm: CalendarMainViewModel) -> some View {
        let currentYear = displaySolarYear(vm: vm)
        return Menu {
            ForEach((currentYear - 5)...(currentYear + 5), id: \.self) { year in
                Button {
                    VNHaptics.impact(enabled: hapticFeedbackEnabled)
                    vm.adapterViewModel.selectMonth(displaySolarMonth(vm: vm), year: year)
                } label: {
                    Text(String(year))
                }
            }
        } label: {
            HStack(spacing: VNSpacing.xs) {
                Text(String(currentYear))
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .fixedSize()
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundColor(.vnTextSecondary)
            .padding(.horizontal, VNSpacing.sm)
            .padding(.vertical, VNSpacing.xs)
            .background(Color.vnBackgroundTertiary, in: RoundedRectangle(cornerRadius: VNCornerRadius.small))
        }
        .frame(minHeight: VNSize.minTapTarget)
        .accessibilityLabel("Đổi năm")
        .accessibilityValue(String(currentYear))
    }

    private func displaySolarYear(vm: CalendarMainViewModel) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        return cal.component(.year, from: vm.adapterViewModel.displayMonthDate)
    }

    private func displaySolarMonth(vm: CalendarMainViewModel) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        return cal.component(.month, from: vm.adapterViewModel.displayMonthDate)
    }

    private func headerButton(
        icon: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.vnTextSecondary)
                .frame(width: VNSize.iconButton, height: VNSize.iconButton)
                .background(Color.vnBackgroundSecondary, in: RoundedRectangle(cornerRadius: VNCornerRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.card)
                        .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                )
                .frame(minWidth: VNSize.minTapTarget, minHeight: VNSize.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func lunarSubtitle(vm: CalendarMainViewModel) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        let year = cal.component(.year, from: vm.adapterViewModel.displayMonthDate)
        let yearPair = CanChiPair.year(for: year)
        return "Năm \(yearPair.description) • Âm Dương Hợp Lịch"
    }
}
