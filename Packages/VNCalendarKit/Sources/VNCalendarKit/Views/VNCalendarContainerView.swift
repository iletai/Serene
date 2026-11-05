import SwiftUI
import CalendarView
import VNCalendarDomain
import VNCalendarLunar
import VNCalendarDesignSystem

public struct VNCalendarContainerView: View {
    private static var vietnamCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        return cal
    }()

    /// Mode change: cross-fade with a slight scale; vnTransition degrades to opacity under Reduce Motion.
    private static let modeTransition = AnyTransition.opacity.combined(with: .scale(scale: 0.97))

    @Bindable var viewModel: VNCalendarAdapterViewModel
    /// Fired directly from inline views, or only after the day-detail sheet has fully dismissed,
    /// so the host can present its own sheet without colliding with this one.
    public var onAddReminderForSelectedDate: () -> Void = {}
    @State private var addReminderAfterDismiss = false

    public init(
        viewModel: VNCalendarAdapterViewModel,
        calendarViewMode: CalendarViewMode = .month,
        onAddReminderForSelectedDate: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onAddReminderForSelectedDate = onAddReminderForSelectedDate
    }

    public var body: some View {
        VStack(spacing: VNSpacing.xs) {
            // Top Mode Switcher (Nhật Lịch, Tháng, Tuần, Năm)
            VNCalendarModePicker(selectedMode: $viewModel.displayMode)
                .padding(.horizontal, VNSpacing.xl)
                .padding(.top, VNSpacing.xs)

            // Dynamic Header Bar
            VNCalendarHeaderView(
                displayMode: viewModel.displayMode,
                monthDate: viewModel.displayMonthDate,
                onPrevious: { viewModel.previous() },
                onNext: { viewModel.next() },
                onToday: { viewModel.selectToday() }
            )

            // Main Content Area by Display Mode
            switch viewModel.displayMode {
            case .block:
                VNBlockCalendarView(
                    dayModel: viewModel.selectedDayModel,
                    onPreviousDay: { viewModel.previousDay() },
                    onNextDay: { viewModel.nextDay() },
                    onSelectToday: { viewModel.selectToday() },
                    onTapDetails: { viewModel.isDetailSheetPresented = true }
                )
                .vnTransition(Self.modeTransition)

            case .month:
                monthGridView
                    .vnTransition(Self.modeTransition)

            case .week:
                VNWeekCalendarView(
                    weekDays: viewModel.currentWeekDates(),
                    selectedDayModel: viewModel.selectedDayModel,
                    onSelectDay: { key, date in
                        viewModel.selectDateKey(key, date: date)
                    },
                    onPreviousWeek: { viewModel.previousWeek() },
                    onNextWeek: { viewModel.nextWeek() },
                    onAddReminder: {
                        onAddReminderForSelectedDate()
                    },
                    onTapDayDetail: {
                        viewModel.isDetailSheetPresented = true
                    }
                )
                .vnTransition(Self.modeTransition)

            case .year:
                VNYearCalendarView(
                    months: viewModel.yearMonthsData(),
                    selectedDateKey: viewModel.selectedDateKey,
                    onSelectMonth: { month in
                        viewModel.selectMonth(month)
                    },
                    onSelectDay: { key, date in
                        viewModel.selectDateKey(key, date: date)
                    }
                )
                .vnTransition(Self.modeTransition)
            }

            if viewModel.displayMode == .month {
                legendRow
            }
        }
        .vnAnimation(VNAnimation.layout, value: viewModel.displayMode)
        .sheet(isPresented: $viewModel.isDetailSheetPresented, onDismiss: {
            guard addReminderAfterDismiss else { return }
            addReminderAfterDismiss = false
            onAddReminderForSelectedDate()
        }, content: {
            if let model = viewModel.selectedDayModel {
                VNDayDetailBottomSheet(
                    dayModel: model,
                    onAddReminder: {
                        addReminderAfterDismiss = true
                        viewModel.isDetailSheetPresented = false
                    }
                )
                .presentationDetents([.fraction(0.55), .fraction(0.85), .large])
                .presentationDragIndicator(.visible)
            }
        })
    }

    // MARK: - Calendar Legend

    private var legendRow: some View {
        HStack(spacing: VNSpacing.md) {
            legendItem(dot: .vnAccentImperialGold, label: "Ngày Hoàng Đạo")
            legendItem(dot: .vnAccentHeritageRed, label: "Giỗ / Sự Kiện Gia Đình")
            legendItem(symbol: "🌕", label: "Rằm / Mùng Một")
        }
        .padding(.top, VNSpacing.xs)
        .padding(.bottom, VNSpacing.sm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Chú thích: chấm vàng là ngày Hoàng Đạo, chấm đỏ là Giỗ, mặt trăng là Rằm Mùng Một")
    }

    private func legendItem(symbol: String, label: String) -> some View {
        HStack(spacing: VNSpacing.xs) {
            Text(symbol)
                .font(.caption2)
            legendLabel(label)
        }
    }

    private func legendItem(dot: Color, label: String) -> some View {
        HStack(spacing: VNSpacing.xs) {
            // Spec: legend dot exactly 8pt
            Circle()
                .fill(dot)
                .frame(width: VNSpacing.sm, height: VNSpacing.sm)
            legendLabel(label)
        }
    }

    private func legendLabel(_ label: String) -> Text {
        Text(label)
            .font(.caption2)
            .foregroundColor(.vnTextSecondary)
    }

    // MARK: - Month Grid View (SwiftUICalendarView 6x7 Matrix)

    private var monthGridView: some View {
        CalendarView(
            selection: $viewModel.selectedDate,
            displayDate: $viewModel.displayMonthDate
        )
        .calendarHeader { _, _, _ in
            EmptyView()
        }
        .calendarWeekdayHeader { _ in
            HStack(spacing: 0) {
                ForEach(["T2", "T3", "T4", "T5", "T6", "T7"], id: \.self) { day in
                    weekdayLabel(day)
                }
                weekdayLabel("CN", sunday: true)
            }
            .padding(.vertical, VNSpacing.xs)
            .overlay(
                Rectangle()
                    .fill(Color.vnBorderSubtle.opacity(0.6))
                    .frame(height: VNBorderWidth.hairline),
                alignment: .bottom
            )
        }
        .calendarDayCell { state in
            let key = DateKey(rawValue: state.dateKey)
            let model = viewModel.dayModel(for: key)
            let isSelected = (key.rawValue == viewModel.selectedDateKey.rawValue)

            VNDayCellView(
                dayModel: model,
                isSelected: isSelected,
                isCurrentMonth: state.isCurrentMonth,
                onSelect: {
                    viewModel.selectDateKey(key, date: state.date)
                }
            )
            .equatable()
        }
        .calendarFirstWeekday(.monday)
        .calendarLocale(Locale(identifier: "vi_VN"))
        .environment(\.calendar, Self.vietnamCalendar)
    }

    private func weekdayLabel(_ day: String, sunday: Bool = false) -> some View {
        Text(day)
            .font(.caption2.weight(sunday ? .bold : .semibold))
            .tracking(0.66)
            .foregroundColor(sunday ? .vnAccentHeritageRed : .vnTextSecondary)
            .frame(maxWidth: .infinity)
    }
}
