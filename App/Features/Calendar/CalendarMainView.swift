import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarKit
import VNCalendarLunar

public struct CalendarMainView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: CalendarMainViewModel?

    public init() {}

    private var activeViewModel: CalendarMainViewModel {
        if let existing = viewModel { return existing }
        return CalendarMainViewModel(
            getMonthCalendarUseCase: container.getMonthCalendarUseCase,
            reminderRepository: container.reminderRepository,
            scheduleReminderUseCase: container.scheduleReminderUseCase,
            evaluateFeatureGateUseCase: container.evaluateFeatureGateUseCase
        )
    }

    public var body: some View {
        @Bindable var vm = activeViewModel
        NavigationStack {
            ScrollView {
                VStack(spacing: VNSpacing.xl) {
                    // Month callout: tiết khí eyebrow + month/year headline + Can Chi seal
                    monthCalloutRow(vm: vm)

                    // Hero almanac card (selected day dashboard)
                    TodayDashboardCard(
                        details: vm.todayDetails,
                        onAddReminder: {
                            vm.checkAndShowReminderForm()
                        },
                        onQuickSearch: {
                            vm.isShowingSearch = true
                        }
                    )
                    .padding(.horizontal, VNSpacing.xl)

                    // Multi-Mode Calendar Container (Nhật Lịch • Tháng • Tuần • Năm)
                    VNCalendarContainerView(
                        viewModel: vm.adapterViewModel,
                        onAddReminderForSelectedDate: {
                            vm.checkAndShowReminderForm()
                        }
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
                    .padding(.horizontal, VNSpacing.xl)
                }
                .padding(.bottom, VNSpacing.xl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                topNavigationHeader(vm: vm)
            }
            .sheet(isPresented: $vm.isShowingCreateReminder) {
                ReminderFormView(
                    initialDate: vm.adapterViewModel.selectedDate,
                    onSave: { newReminder in
                        vm.saveReminder(newReminder)
                    }
                )
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $vm.isShowingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $vm.isShowingSearch) {
                OmniSearchView()
            }
            .sheet(isPresented: $vm.isShowingSettings) {
                SettingsView()
            }
            .task {
                if viewModel == nil {
                    viewModel = activeViewModel
                }
                await viewModel?.loadData()
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
                triggerHaptic()
                vm.adapterViewModel.selectToday()
            }

            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text("AN NIÊN")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(.vnAccentDeepPrimary)

                Text(lunarSubtitle(vm: vm))
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.66)
                    .foregroundColor(.vnTextSecondary)
            }

            Spacer()

            yearSwitcherPill(vm: vm)

            headerButton(
                icon: "gearshape",
                accessibilityLabel: "Cài đặt ứng dụng"
            ) {
                triggerHaptic()
                vm.isShowingSettings = true
            }
        }
        .padding(.horizontal, VNSpacing.xl)
        .padding(.vertical, VNSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.vnBackgroundPrimary.opacity(0.9)
                .background(.ultraThinMaterial)
        )
        .shadow(color: VNShadow.card.color, radius: VNShadow.card.radius, x: VNShadow.card.x, y: VNShadow.card.y)
    }

    private func yearSwitcherPill(vm: CalendarMainViewModel) -> some View {
        let currentYear = displaySolarYear(vm: vm)
        return Menu {
            ForEach((currentYear - 5)...(currentYear + 5), id: \.self) { year in
                Button {
                    triggerHaptic()
                    vm.adapterViewModel.selectMonth(displaySolarMonth(vm: vm), year: year)
                } label: {
                    Text(String(year))
                }
            }
        } label: {
            HStack(spacing: VNSpacing.xs) {
                Text(String(currentYear))
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundColor(.vnTextSecondary)
            .padding(.horizontal, VNSpacing.sm)
            .padding(.vertical, VNSpacing.xs)
            .background(Color.vnAncientSand, in: RoundedRectangle(cornerRadius: VNCornerRadius.small))
        }
        .frame(minHeight: 44)
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
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.vnTextSecondary)
                .frame(width: 36, height: 36)
                .background(Color.vnBackgroundSecondary, in: RoundedRectangle(cornerRadius: VNCornerRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.card)
                        .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                )
                .frame(minWidth: 44, minHeight: 44)
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
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.1)
                    .foregroundColor(.vnAccentImperialGold)

                Text(monthCalloutTitle(vm: vm))
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(.vnTextPrimary)
            }

            Spacer(minLength: VNSpacing.sm)

            monthSealBadge(vm: vm)
        }
        .padding(.horizontal, VNSpacing.xl)
        .padding(.top, VNSpacing.xs)
    }

    private func monthSealBadge(vm: CalendarMainViewModel) -> some View {
        let yearPair = displayYearCanChi(vm: vm)
        return VStack(spacing: VNSpacing.space2) {
            Text(yearPair.stem.vietnameseName.uppercased())
            Text(yearPair.branch.vietnameseName.uppercased())
        }
        .font(.system(size: 10, weight: .bold, design: .serif))
        .foregroundColor(.vnAccentDeepPrimary)
        .frame(width: 40, height: 40)
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

    private func triggerHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}
