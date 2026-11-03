import SwiftUI
import VNCalendarDesignSystem
import VNCalendarDomain

public struct PrayerCategoryCard: View {
    public let category: PrayerCategory
    public let count: Int
    public let isSelected: Bool
    public let action: () -> Void
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true

    public init(
        category: PrayerCategory,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.category = category
        self.count = count
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(
            action: {
                VNHaptics.impact(.light, enabled: hapticFeedbackEnabled)
                action()
            },
            label: {
                HStack(spacing: VNSpacing.sm) {
                    Image(systemName: category.iconName)
                        .font(.vnFootnote)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .vnAccentDeepPrimary : .vnTextSecondary)
                        .accessibilityHidden(true)

                    Text(category.rawValue)
                        .font(.vnCaption1)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .vnAccentDeepPrimary : .vnTextSecondary)
                        .lineLimit(1)

                    Text("\(count)")
                        .font(.vnCaption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .vnAccentDeepPrimary : .vnTextTertiary)
                        .accessibilityLabel("\(count) bài")
                        .padding(.horizontal, VNSpacing.xs)
                        .padding(.vertical, VNSpacing.space2)
                        .background(isSelected ? Color.vnAccentDeepPrimary.opacity(0.12) : Color.vnBackgroundTertiary)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, VNSpacing.md)
                .padding(.vertical, VNSpacing.sm)
                .frame(minHeight: VNSize.minTapTarget)
                .background(isSelected ? Color.vnAccentRedSurface : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.vnAccentHeritageRed.opacity(0.25) : Color.vnBorderSubtle,
                            lineWidth: isSelected ? VNBorderWidth.regular : VNBorderWidth.hairline
                        )
                )
            }
        )
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
