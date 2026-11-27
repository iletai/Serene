import SwiftUI
import VNCalendarDesignSystem

public struct VNDayCellView: View, Equatable {
    public let dayModel: VNCalendarDayModel?
    public let isSelected: Bool
    public let isCurrentMonth: Bool
    public let highlightMoon: Bool
    public let onSelect: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var numeralSize: CGFloat = 34
    @ScaledMetric(relativeTo: .body) private var solarFontSize: CGFloat = 19
    @ScaledMetric(relativeTo: .caption2) private var lunarFontSize: CGFloat = 10

    public init(
        dayModel: VNCalendarDayModel?,
        isSelected: Bool,
        isCurrentMonth: Bool = true,
        highlightMoon: Bool = true,
        onSelect: @escaping () -> Void
    ) {
        self.dayModel = dayModel
        self.isSelected = isSelected
        self.isCurrentMonth = isCurrentMonth
        self.highlightMoon = highlightMoon
        self.onSelect = onSelect
    }

    nonisolated public static func == (lhs: VNDayCellView, rhs: VNDayCellView) -> Bool {
        lhs.dayModel == rhs.dayModel &&
        lhs.isSelected == rhs.isSelected &&
        lhs.isCurrentMonth == rhs.isCurrentMonth &&
        lhs.highlightMoon == rhs.highlightMoon
    }

    public var body: some View {
        VStack(spacing: VNSpacing.space2) {
            if let model = dayModel {
                Text("\(model.solarDay)")
                    .font(.vnDisplay(size: solarFontSize, weight: solarWeight))
                    .monospacedDigit()
                    .foregroundColor(numeralColor)
                    .frame(width: numeralSize, height: numeralSize)
                    .background(numeralBackground, in: Circle())
                    .vnSelectionPulse(active: isSelected)

                Text(model.lunarDayText)
                    .font(.vnDisplay(size: lunarFontSize, weight: lunarWeight))
                    .monospacedDigit()
                    .foregroundColor(lunarColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                indicatorDots
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 60, alignment: .top)
        .padding(.top, VNSpacing.xs)
        .background(cellBackground)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small, style: .continuous))
        .opacity(isCurrentMonth ? 1.0 : 0.4)
        .animation(reduceMotion ? nil : VNAnimation.cellSelection, value: isSelected)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .onTapRelease(perform: onSelect)
    }

    // MARK: - Indicator Dots (Giỗ red / Hoàng Đạo gold)

    private var indicatorDots: some View {
        HStack(spacing: 3) {
            if dayModel?.hasAncestorDeathAnniversary == true {
                dot(Color.vnAccentHeritageRed)
            }
            if dayModel?.isAuspiciousDay == true {
                dot(Color.vnAccentImperialGold)
            }
            if dayModel?.hasAncestorDeathAnniversary != true && dayModel?.isAuspiciousDay != true {
                Color.clear.frame(width: 5, height: 5)
            }
        }
        .frame(height: 5)
    }

    private func dot(_ color: Color) -> some View {
        Circle().fill(color).frame(width: 5, height: 5)
    }

    private var isToday: Bool {
        dayModel?.isToday == true
    }

    private var isFirstLunarDay: Bool {
        highlightMoon && isCurrentMonth && dayModel?.isFirstDayOfLunarMonth == true
    }

    private var isFullMoon: Bool {
        highlightMoon && isCurrentMonth && dayModel?.isFullMoonDay == true
    }

    private var solarWeight: Font.Weight {
        if isToday || isSelected || isFirstLunarDay || isFullMoon { return .semibold }
        return .regular
    }

    /// Selected numeral sits on a dark disc; today alone is Hội An blue ink.
    private var numeralColor: Color {
        if isSelected { return isToday ? .vnOnAccent : .vnBackgroundSecondary }
        if isToday { return .vnAccentSky }
        if !isCurrentMonth { return .vnTextTertiary }
        return .vnTextPrimary
    }

    private var numeralBackground: Color {
        if isSelected { return isToday ? .vnAccentSky : .vnTextPrimary }
        return .clear
    }

    private var lunarColor: Color {
        if isSelected { return isToday ? .vnOnAccent : .vnTextSecondary }
        if isFullMoon { return .vnAccentGoldText }
        if isFirstLunarDay { return .vnAccentSky }
        if !isCurrentMonth { return .vnTextTertiary }
        return .vnTextSecondary
    }

    private var lunarWeight: Font.Weight {
        if isFirstLunarDay || isFullMoon { return .bold }
        return .medium
    }

    private var cellBackground: Color {
        if isSelected { return Color.vnAccentSky.opacity(0.10) }
        if isFullMoon { return .vnAccentGoldSurface }
        if isFirstLunarDay { return .vnAccentSkySurface }
        return .clear
    }

    private var accessibilityText: String {
        guard let model = dayModel else { return String(localized: "calendar.cell.out_of_month_accessibility") }
        var text = "\(model.weekdayName), ngày \(model.solarDay) tháng \(model.solarMonth) Dương lịch. "
        text += "Âm lịch ngày \(model.lunarDay) \(model.lunarMonthName) năm \(model.lunarYearCanChi). "
        if model.isFirstDayOfLunarMonth { text += "Mùng một đầu tháng. " }
        if model.isFullMoonDay { text += "Ngày Rằm mười lăm. " }
        if let term = model.solarTermName { text += "Tiết khí \(term). " }
        if model.hasAncestorDeathAnniversary { text += "Có ngày Giỗ gia tiên. " }
        if model.isToday { text += "Hôm nay. " }
        if isSelected { text += "Đang chọn." }
        return text
    }
}
