import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarKit
import VNCalendarLunar

public struct CalendarMainView: View {
    @State private var container = AppContainer.shared
    @State private var adapterViewModel = VNCalendarAdapterViewModel()
    @State private var todayDetails: DayCalendarDetails?
    @State private var isShowingCreateReminder = false
    @State private var isShowingPaywall = false
    @State private var isShowingSearch = false
    @State private var isShowingSettings = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VNSpacing.xl) {
                    // Month callout: tiết khí eyebrow + month/year headline + Can Chi seal
                    monthCalloutRow

                    // Hero almanac card (selected day dashboard)
                    TodayDashboardCard(
                        details: todayDetails,
                        onAddReminder: {
                            checkAndShowReminderForm()
                        },
                        onQuickSearch: {
                            isShowingSearch = true
                        }
                    )
                    .padding(.horizontal, VNSpacing.xl)

                    // Multi-Mode Calendar Container (Nhật Lịch • Tháng • Tuần • Năm)
                    VNCalendarContainerView(
                        viewModel: adapterViewModel,
                        onAddReminderForSelectedDate: {
                            checkAndShowReminderForm()
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
                // Pill space is reserved by MainTabView.safeAreaInset; this is just a section gap.
                .padding(.bottom, VNSpacing.xl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                topNavigationHeader
            }
            .sheet(isPresented: $isShowingCreateReminder) {
                ReminderFormView(
                    initialDate: adapterViewModel.selectedDate,
                    onSave: { newReminder in
                        saveReminder(newReminder)
                    }
                )
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $isShowingSearch) {
                OmniSearchView()
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .task {
                await loadData()
            }
        }
    }

    // MARK: - Top Editorial Header
    private var topNavigationHeader: some View {
        HStack(alignment: .center, spacing: VNSpacing.sm) {
            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text("AN NIÊN")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(.vnAccentDeepPrimary)

                Text(lunarSubtitle)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.66)
                    .foregroundColor(.vnTextSecondary)
            }

            Spacer()

            HStack(spacing: VNSpacing.xs) {
                headerButton(
                    icon: "magnifyingglass",
                    accessibilityLabel: "Tìm kiếm ngày lễ, tiền nhân"
                ) {
                    triggerHaptic()
                    isShowingSearch = true
                }

                headerButton(
                    icon: "gearshape.fill",
                    accessibilityLabel: "Cài đặt ứng dụng"
                ) {
                    triggerHaptic()
                    isShowingSettings = true
                }
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

    // 36pt rounded hit target per canonical top bar.
    private func headerButton(
        icon: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.vnAccentDeepPrimary)
                .frame(width: 36, height: 36)
                .background(Color.vnBackgroundSecondary)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                )
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Month Callout + Seal
    private var monthCalloutRow: some View {
        HStack(alignment: .center, spacing: VNSpacing.md) {
            VStack(alignment: .leading, spacing: 3) {
                Text(monthCalloutEyebrow)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.1)
                    .foregroundColor(.vnAccentImperialGold)

                Text(monthCalloutTitle)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(.vnTextPrimary)
            }

            Spacer(minLength: VNSpacing.sm)

            monthSealBadge
        }
        .padding(.horizontal, VNSpacing.xl)
        .padding(.top, VNSpacing.xs)
    }

    private var monthSealBadge: some View {
        let yearPair = displayYearCanChi
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

    private var monthCalloutEyebrow: String {
        let name = AstronomicalMath.solarTerm(at: AstronomicalMath.julianDay(from: solarTermAnchorDate))
            .vietnameseName.uppercased()
        return "TIẾT KHÍ · TIẾT \(name)"
    }

    private var monthCalloutTitle: String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        let month = cal.component(.month, from: adapterViewModel.displayMonthDate)
        let year = cal.component(.year, from: adapterViewModel.displayMonthDate)
        return "\(solarMonthNames[month - 1]) · \(year)"
    }

    private var displayYearCanChi: CanChiPair {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        let year = cal.component(.year, from: adapterViewModel.displayMonthDate)
        return CanChiPair.year(for: year)
    }

    private var solarTermAnchorDate: SolarDate {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        return SolarDate(from: adapterViewModel.displayMonthDate, calendar: cal)
    }

    private var solarMonthNames: [String] {
        [
            "Tháng Một", "Tháng Hai", "Tháng Ba", "Tháng Tư",
            "Tháng Năm", "Tháng Sáu", "Tháng Bảy", "Tháng Tám",
            "Tháng Chín", "Tháng Mười", "Tháng Mười Một", "Tháng Mười Hai"
        ]
    }

    private var lunarSubtitle: String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        let year = cal.component(.year, from: adapterViewModel.displayMonthDate)
        let yearPair = CanChiPair.year(for: year)
        return "Năm \(yearPair.description) • Âm Dương Hợp Lịch"
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }

    private func loadData() async {
        let now = Date()
        let solar = SolarDate(from: now)
        todayDetails = try? await container.getMonthCalendarUseCase.execute(solarDate: solar)

        if let reminders = try? await container.reminderRepository.fetchAllReminders() {
            adapterViewModel.updateReminders(reminders)
            try? await container.notificationEngine.pruneAndSchedule(reminders: reminders)
        }
    }

    private func checkAndShowReminderForm() {
        Task {
            do {
                let canAdd = try await container.evaluateFeatureGateUseCase.canAddReminder()
                if canAdd {
                    isShowingCreateReminder = true
                } else {
                    isShowingPaywall = true
                }
            } catch {
                // Fail closed: a gate error must not open the create form.
                isShowingPaywall = true
            }
        }
    }

    private func saveReminder(_ reminder: ReminderEvent) {
        Task {
            do {
                try await container.scheduleReminderUseCase.execute(save: reminder)
            } catch {
                // Surface save failures instead of silently dropping the reminder.
            }
            await loadData()
        }
    }
}
