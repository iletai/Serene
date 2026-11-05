import SwiftUI
import VNCalendarDesignSystem
import VNCalendarDomain
import VNCalendarLunar

public struct VNYearCalendarView: View {
    public let months: [VNYearMonthModel]
    public let selectedDateKey: DateKey
    public let onSelectMonth: (Int) -> Void
    public let onSelectDay: (DateKey, Date) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 3 columns by default; 2 from XXL up so month names and day numerals never truncate.
    private var columns: [GridItem] {
        let count = dynamicTypeSize >= .xxLarge ? 2 : 3
        return Array(repeating: GridItem(.flexible(), spacing: VNSpacing.sm, alignment: .top), count: count)
    }

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
        // No ScrollView: the host screen owns the single vertical scroll.
        LazyVGrid(columns: columns, spacing: VNSpacing.md) {
            ForEach(months) { monthModel in
                Button {
                    onSelectMonth(monthModel.month)
                } label: {
                    miniMonthCard(monthModel)
                }
                .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.97))
            }
        }
        .padding(.horizontal, VNSpacing.xl)
        .padding(.vertical, VNSpacing.sm)
        .padding(.bottom, VNSpacing.xl)
    }

    private func miniMonthCard(_ monthModel: VNYearMonthModel) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text(monthModel.monthName)
                .font(.system(.footnote, design: .serif).weight(.bold))
                .foregroundColor(.vnTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            // Day grid is capped at xLarge so 7 numerals always fit a column; the card itself reflows to 2 columns.
            let dayColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: dayColumns, spacing: VNSpacing.space2) {
                ForEach(monthModel.days) { day in
                    miniDayCell(day: day, targetMonth: monthModel.month)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
        }
        .padding(VNSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle.opacity(0.6), lineWidth: VNBorderWidth.hairline)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(monthModel.monthName)
        .accessibilityAddTraits(.isButton)
    }

    /// Day numeral only: today = gold fill, selected = red fill, memorial = dot. Days outside the month are blank.
    @ViewBuilder
    private func miniDayCell(day: VNCalendarDayModel, targetMonth: Int) -> some View {
        if day.solarMonth == targetMonth {
            let isSelected = day.dateKey == selectedDateKey
            let hasMemorial = day.hasAncestorDeathAnniversary || !day.anniversaries.isEmpty
            Text("\(day.solarDay)")
                .font(.system(.caption2).weight((isSelected || day.isToday) ? .bold : .regular))
                .foregroundColor(isSelected ? .vnOnAccent : .vnTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, minHeight: 18)
                .background(
                    isSelected ? Color.vnAccentHeritageRed :
                    (day.isToday ? Color.vnAccentImperialGold.opacity(0.35) : Color.clear)
                )
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.micro))
                .overlay(alignment: .bottom) {
                    if hasMemorial {
                        Circle()
                            .fill(isSelected ? Color.vnOnAccent : Color.vnAccentHeritageRed)
                            .frame(width: 3, height: 3)
                    }
                }
        } else {
            Color.clear.frame(height: 18)
        }
    }
}
