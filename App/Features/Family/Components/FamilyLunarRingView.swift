import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

/// Horizontal 12-month lunar memorial ring (prototype `.lunar-ring`). Tapping a month spotlights
/// the people whose memorial falls in it on the tree.
struct FamilyLunarRingView: View {
    let months: [FamilyRingMonth]
    let currentMonth: Int
    let nextMonth: Int?
    let highlightedMonth: Int?
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VNSpacing.sm) {
                ForEach(months) { month in
                    FamilyLunarRingChip(
                        month: month,
                        isCurrent: month.month == currentMonth,
                        isNext: month.month == nextMonth,
                        isSelected: month.month == highlightedMonth
                    ) { onSelect(month.month) }
                }
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.top, VNSpacing.xs)
            .padding(.bottom, VNSpacing.sm)
        }
        .scrollClipDisabled()
    }
}

private struct FamilyLunarRingChip: View {
    let month: FamilyRingMonth
    let isCurrent: Bool
    let isNext: Bool
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let corner: CGFloat = 18

    private var accessibilityText: String {
        var text = String(format: String(localized: "family.ring.a11y_month"), month.month)
        if isCurrent { text += ", " + String(localized: "family.ring.a11y_current") }
        text += ": "
        if month.isEmpty {
            text += String(localized: "family.ring.a11y_none")
        } else {
            text += month.members
                .map { String(format: String(localized: "family.ring.a11y_member"), $0.title, $0.day) }
                .joined(separator: ", ")
        }
        return text
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: VNSpacing.xs + 2) {
                Text(String(format: String(localized: "family.ring.month"), month.month).uppercased())
                    .font(.vnDisplay(.caption2, weight: .bold))
                    .tracking(0.4)
                    .foregroundColor(nameColor)
                    .lineLimit(1)
                faces
                Text(month.members.map { String($0.day) }.joined(separator: " · "))
                    .font(.vnDisplay(.caption2, weight: .bold))
                    .foregroundColor(isSelected ? .vnAccentImperialGold : .vnAccentGoldText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(minHeight: 14)
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .padding(.vertical, 10)
            .padding(.horizontal, VNSpacing.xs + 2)
            .frame(width: 80)
            .background(background)
            .overlay(border)
            .vnNextGlow(isActive: isNext && !isSelected, cornerRadius: corner)
            .opacity(month.isEmpty ? 0.55 : 1)
            .offset(y: isSelected && !reduceMotion ? -2 : 0)
            .vnAnimation(VNMotion.Easing.card, value: isSelected)
        }
        .buttonStyle(.vnPress)
        .vnSelectionFeedback(trigger: isSelected)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var nameColor: Color {
        if isSelected { return .vnOnNight }
        return isCurrent ? .vnAccentHeritageRed : .vnTextSecondary
    }

    private var faces: some View {
        HStack(spacing: -8) {
            if month.isEmpty {
                Text("—").foregroundColor(.vnTextTertiary).frame(height: 28)
            } else {
                ForEach(Array(month.members.prefix(3))) { member in
                    Text(FamilyMemberInfo.initial(of: member.title))
                        .font(.vnDisplay(.caption, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.vnAccentSky, in: Circle())
                        .overlay(Circle().strokeBorder(isSelected ? Color.vnNight : Color.vnBackgroundSecondary, lineWidth: 2))
                }
            }
        }
        .frame(minHeight: 28)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: corner).fill(Color.vnNight)
        } else {
            RoundedRectangle(cornerRadius: corner).fill(Color.vnBackgroundSecondary)
                .shadow(color: VNShadow.card.color, radius: VNShadow.card.radius, y: VNShadow.card.y)
        }
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: corner)
            .strokeBorder(
                isCurrent && !isSelected ? Color.vnAccentHeritageRed : Color.vnBorderSubtle,
                lineWidth: isCurrent && !isSelected ? VNBorderWidth.active : VNBorderWidth.hairline
            )
    }
}
