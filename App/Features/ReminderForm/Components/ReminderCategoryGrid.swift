import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

struct ReminderCategoryGrid: View {
    @Binding var selectedCategory: ReminderCategory
    @ScaledMetric(relativeTo: .subheadline) private var iconBox: CGFloat = 28

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text("PHÂN LOẠI SỰ KIỆN")
                .font(.caption2.weight(.medium))
                .tracking(0.66)
                .foregroundColor(.vnAccentGoldText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: VNSpacing.sm) {
                categoryCard(cat: .deathAnniversary, icon: "flame.fill", subtitle: "Hiếu đạo tổ tiên", isMain: true)
                categoryCard(cat: .ancestral, icon: "person.3.fill", subtitle: "Họp họ, tôn tạo")
                categoryCard(cat: .birthday, icon: "gift.fill", subtitle: "Âm hoặc Dương")
                categoryCard(cat: .worship, icon: "sparkles", subtitle: "Rằm, Mùng một")
                categoryCard(cat: .wedding, icon: "heart.fill", subtitle: "Gắn kết lứa đôi")
                categoryCard(cat: .other, icon: "calendar", subtitle: "Ghi nhớ gia đình")
            }
        }
    }

    private func categoryCard(cat: ReminderCategory, icon: String, subtitle: String, isMain: Bool = false) -> some View {
        let isSelected = selectedCategory == cat
        let tileShape = RoundedRectangle(cornerRadius: VNCornerRadius.card)
        return Button(
            action: { selectedCategory = cat },
            label: {
                HStack(spacing: VNSpacing.sm) {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(isSelected ? .vnAccentHeritageRed : .vnAccentGoldText)
                        .frame(width: iconBox, height: iconBox)
                        .accessibilityHidden(true)
                        .background(
                            RoundedRectangle(cornerRadius: VNCornerRadius.small)
                                .fill(isSelected ? Color.vnAccentRedSurface : Color.vnBackgroundPrimary)
                        )

                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        Text(cat.title)
                            .font(.system(.footnote, design: .serif, weight: .semibold))
                            .foregroundColor(isSelected ? .vnAccentHeritageRed : .vnTextPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(isSelected ? .vnAccentHeritageRed : .vnTextSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer(minLength: 0)

                    if isMain {
                        Text("Chính")
                            .font(.system(.caption2, design: .serif, weight: .semibold))
                            .foregroundColor(.vnAccentHeritageRed)
                            .padding(.horizontal, VNSpacing.xs)
                            .padding(.vertical, VNSpacing.space2)
                            .background(Capsule().fill(Color.vnAccentHeritageRed.opacity(0.12)))
                    }
                }
                .padding(VNSpacing.sm)
                .frame(maxWidth: .infinity, minHeight: VNSize.minTapTarget, alignment: .leading)
                .background(isSelected ? Color.vnAccentRedSurface : Color.vnBackgroundTertiary)
                .clipShape(tileShape)
                .overlay(
                    tileShape
                        .stroke(isSelected ? Color.vnAccentHeritageRed : Color.vnBorderSubtle, lineWidth: VNBorderWidth.regular)
                )
            }
        )
        .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
