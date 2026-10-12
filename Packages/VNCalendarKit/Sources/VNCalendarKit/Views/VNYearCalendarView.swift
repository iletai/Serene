import SwiftUI
import VNCalendarDesignSystem
import VNCalendarDomain
import VNCalendarLunar

public struct VNYearCalendarView: View {
    public let months: [VNYearMonthModel]
    public let selectedDateKey: DateKey
    public let onSelectMonth: (Int) -> Void
    public let onSelectDay: (DateKey, Date) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: VNSpacing.sm),
        GridItem(.flexible(), spacing: VNSpacing.sm),
        GridItem(.flexible(), spacing: 10)
    ]

    public init(
        months: [VNYearMonthModel],
        selectedDateKey: DateKey,
        onSelectMonth: @escaping (Int) -> Void,
        onSelectDay: @escaping (DateKey, Date) -> Void
    ) {
        self.months = months
        self.selectedDateKey = selectedDateKey
        self.onSelectMonth = onSelectMonth
        self.onSelectDay = onSelectDay
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: VNSpacing.md) {
                ForEach(months) { monthModel in
                    Button {
                        onSelectMonth(monthModel.month)
                    } label: {
                        miniMonthCard(monthModel)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, VNSpacing.xl)
            .padding(.vertical, VNSpacing.sm)
            .padding(.bottom, VNSpacing.xl)
        }
    }

    private func miniMonthCard(_ monthModel: VNYearMonthModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Month Header
            HStack {
                Text(monthModel.monthName)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(.vnTextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.vnTextTertiary)
            }
            .padding(.bottom, VNSpacing.space2)

            // Mini Weekday Labels
            HStack(spacing: 0) {
                ForEach(["H", "B", "T", "N", "S", "B", "C"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.vnTextTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Mini 6x7 Grid of Days
            let dayColumns = Array(repeating: GridItem(.flexible(), spacing: VNSpacing.space2), count: 7)
            LazyVGrid(columns: dayColumns, spacing: VNSpacing.space2) {
                ForEach(monthModel.days) { day in
                    miniDayCell(day: day, targetMonth: monthModel.month)
                }
            }
        }
        .padding(VNSpacing.sm)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle.opacity(0.6), lineWidth: VNBorderWidth.hairline)
        )
    }

    private func miniDayCell(day: VNCalendarDayModel, targetMonth: Int) -> some View {
        let isCurrentMonth = (day.solarMonth == targetMonth)
        let isSelected = (day.dateKey == selectedDateKey)
        let isToday = day.isToday
        let isSpecialLunar = (day.isFirstDayOfLunarMonth || day.isFullMoonDay)

        return Text("\(day.solarDay)")
            .font(.system(size: 9, weight: (isSelected || isToday) ? .bold : .regular))
            .foregroundColor(
                isSelected ? .white :
                (isToday ? .vnAccentImperialGold :
                (isCurrentMonth ? (isSpecialLunar ? .vnAccentHeritageRed : .vnTextPrimary) : .vnTextTertiary.opacity(0.3)))
            )
            .frame(maxWidth: .infinity, minHeight: 14)
            .background(
                isSelected ? Color.vnAccentHeritageRed :
                (isToday ? Color.vnAccentImperialGold.opacity(0.2) : Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
    }
}
