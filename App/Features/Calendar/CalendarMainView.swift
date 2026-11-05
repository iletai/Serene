import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarKit
import VNCalendarLunar

public struct CalendarMainView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @ScaledMetric(relativeTo: .caption2) private var sealSize = VNSize.iconButton
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
            VStack(spacing: VNSpacing.sectionGap) {
                // Month callout: tiết khí eyebrow + month/year headline + Can Chi seal
                monthCalloutRow(vm: vm)

                // Hero almanac card (selected day dashboard)
                TodayDashboardCard(
                    details: vm.todayDetails,
                    onAddReminder: { presentReminderForm(vm: vm) },
                    onQuickSearch: { router.present(sheet: .search) }
                )
                .padding(.horizontal, VNSpacing.screenMargin)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("today.card")

                // Multi-Mode Calendar Container (Nhật Lịch • Tháng • Tuần • Năm).
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
        .vnTopBarBackground()
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

    // MARK: - Month Callout + Seal
    private func monthCalloutRow(vm: CalendarMainViewModel) -> some View {
        HStack(alignment: .center, spacing: VNSpacing.md) {
            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text(monthCalloutEyebrow(vm: vm))
                    .font(.caption2.weight(.medium))
                    .tracking(1.1)
                    .foregroundColor(.vnAccentGoldText)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                Text(monthCalloutTitle(vm: vm))
                    .font(.system(.title2, design: .serif).weight(.semibold))
                    .foregroundColor(.vnTextPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: VNSpacing.sm)

            monthSealBadge(vm: vm)
        }
        .padding(.horizontal, VNSpacing.screenMargin)
        .padding(.top, VNSpacing.xs)
    }

    private func monthSealBadge(vm: CalendarMainViewModel) -> some View {
        let yearPair = displayYearCanChi(vm: vm)
        return VStack(spacing: VNSpacing.space2) {
            Text(yearPair.stem.vietnameseName.uppercased())
            Text(yearPair.branch.vietnameseName.uppercased())
        }
        .font(.system(.caption2, design: .serif).weight(.bold))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .foregroundColor(.vnAccentDeepPrimary)
        // ponytail: decorative seal capped at 1.5x so the month title keeps the row width.
        .frame(width: min(sealSize, VNSize.iconButton * 1.5), height: min(sealSize, VNSize.iconButton * 1.5))
        .background(Color.vnSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.small)
                .stroke(Color.vnAccentDeepPrimary, lineWidth: VNBorderWidth.focus)
        )
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.small)
                .inset(by: 3)
                .stroke(Color.vnAccentDeepPrimary.opacity(0.4), lineWidth: VNBorderWidth.hairline)
        )
        .shadow(color: Color.vnAccentDeepPrimary.opacity(0.15), radius: 3, x: 0, y: 2)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ấn triện năm \(yearPair.description)")
    }

    private func monthCalloutEyebrow(vm: CalendarMainViewModel) -> String {
        let name = AstronomicalMath.solarTerm(at: AstronomicalMath.julianDay(from: solarTermAnchorDate(vm: vm)))
            .vietnameseName.uppercased()
        return "TIẾT KHÍ · TIẾT \(name)"
    }

    private func monthCalloutTitle(vm: CalendarMainViewModel) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        let month = cal.component(.month, from: vm.adapterViewModel.displayMonthDate)
        let year = cal.component(.year, from: vm.adapterViewModel.displayMonthDate)
        return "\(solarMonthNames[month - 1]) · \(year)"
    }

    private func displayYearCanChi(vm: CalendarMainViewModel) -> CanChiPair {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        let year = cal.component(.year, from: vm.adapterViewModel.displayMonthDate)
        return CanChiPair.year(for: year)
    }

    private func solarTermAnchorDate(vm: CalendarMainViewModel) -> SolarDate {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        return SolarDate(from: vm.adapterViewModel.displayMonthDate, calendar: cal)
    }

    private var solarMonthNames: [String] {
        [
            "Tháng Một", "Tháng Hai", "Tháng Ba", "Tháng Tư",
            "Tháng Năm", "Tháng Sáu", "Tháng Bảy", "Tháng Tám",
            "Tháng Chín", "Tháng Mười", "Tháng Mười Một", "Tháng Mười Hai"
        ]
    }

    private func lunarSubtitle(vm: CalendarMainViewModel) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        let year = cal.component(.year, from: vm.adapterViewModel.displayMonthDate)
        let yearPair = CanChiPair.year(for: year)
        return "Năm \(yearPair.description) • Âm Dương Hợp Lịch"
    }
}
