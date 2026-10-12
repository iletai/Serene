import SwiftUI
import VNCalendarDesignSystem

public struct VNDayCellView: View, Equatable {
    public let dayModel: VNCalendarDayModel?
    public let isSelected: Bool
    public let isCurrentMonth: Bool
    public let onSelect: () -> Void

    @ScaledMetric(relativeTo: .body) private var solarFontSize: CGFloat = 15
    @ScaledMetric(relativeTo: .caption2) private var lunarFontSize: CGFloat = 10

    public init(
        dayModel: VNCalendarDayModel?,
        isSelected: Bool,
        isCurrentMonth: Bool = true,
        onSelect: @escaping () -> Void
    ) {
        self.dayModel = dayModel
        self.isSelected = isSelected
        self.isCurrentMonth = isCurrentMonth
        self.onSelect = onSelect
    }

    nonisolated public static func == (lhs: VNDayCellView, rhs: VNDayCellView) -> Bool {
        lhs.dayModel == rhs.dayModel &&
        lhs.isSelected == rhs.isSelected &&
        lhs.isCurrentMonth == rhs.isCurrentMonth
    }

    public var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 1) {
                if let model = dayModel {
                    Text("\(model.solarDay)")
                        .font(.system(size: solarFontSize, weight: solarWeight))
                        .foregroundColor(solarColor)

                    Text(model.lunarDayText)
                        .font(.system(size: lunarFontSize, weight: lunarWeight))
                        .foregroundColor(lunarColor)

                    indicatorDot
                } else {
                    Spacer(minLength: 0)
                }
            }
            .padding(.vertical, VNSpacing.xs)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
            .overlay(
                RoundedRectangle(cornerRadius: VNCornerRadius.small)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .opacity(isCurrentMonth ? 1.0 : 0.35)
            .contentShape(Rectangle())
        }
        .buttonStyle(VNCellPressButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Indicator Dot (Hoàng Đạo gold / Giỗ red)

    @ViewBuilder
    private var indicatorDot: some View {
        if dayModel?.hasAncestorDeathAnniversary == true {
            Circle()
                .fill(isToday ? Color.vnRicePaperWhite : Color.vnAccentHeritageRed)
                .frame(width: 4, height: 4)
        } else if dayModel?.isAuspiciousDay == true {
            Circle()
                .fill(Color.vnAccentImperialGold)
                .frame(width: 4, height: 4)
        } else {
            Color.clear.frame(width: 4, height: 4)
        }
    }

    private var isToday: Bool {
        dayModel?.isToday == true
    }

    private var isFirstLunarDay: Bool {
        isCurrentMonth && dayModel?.isFirstDayOfLunarMonth == true
    }

    private var isFullMoon: Bool {
        isCurrentMonth && dayModel?.isFullMoonDay == true
    }

    private var solarWeight: Font.Weight {
        if isToday || isFirstLunarDay { return .bold }
        return .medium
    }

    private var solarColor: Color {
        if isToday { return .vnRicePaperWhite }
        if isFullMoon { return .vnAccentImperialGold }
        if isFirstLunarDay { return .vnAccentHeritageRed }
        if !isCurrentMonth { return .vnTextTertiary }
        return .vnTextPrimary
    }

    private var lunarColor: Color {
        if isToday { return .vnRicePaperWhite }
        if isFullMoon { return .vnAccentImperialGold }
        if isFirstLunarDay { return .vnAccentHeritageRed }
        if !isCurrentMonth { return .vnTextTertiary.opacity(0.7) }
        return .vnTextSecondary
    }

    private var lunarWeight: Font.Weight {
        if isToday || isFirstLunarDay || isFullMoon { return .bold }
        return .regular
    }

    private var backgroundColor: Color {
        if isToday { return .vnAccentHeritageRed }
        if isSelected { return .vnBackgroundSecondary }
        if isFullMoon { return .vnAccentGoldSurface }
        if isFirstLunarDay { return .vnAccentRedSurface }
        return .clear
    }

    private var borderColor: Color {
        if isToday { return .clear }
        if isFullMoon { return .vnAccentImperialGold }
        if isFirstLunarDay { return .vnAccentHeritageRed }
        if isSelected { return .vnAccentDeepPrimary }
        return .clear
    }

    private var borderWidth: CGFloat {
        if isToday { return 0 }
        if isFullMoon || isFirstLunarDay || isSelected { return 1 }
        return 0
    }

    private var accessibilityText: String {
        guard let model = dayModel else { return "Ô ngoài tháng" }
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
