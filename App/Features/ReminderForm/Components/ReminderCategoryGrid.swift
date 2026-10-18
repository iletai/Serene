import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

struct ReminderCategoryGrid: View {
    @Binding var selectedCategory: ReminderCategory

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text("PHÂN LOẠI SỰ KIỆN")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.66)
                .foregroundColor(.vnAccentImperialGold)

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
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isSelected ? .vnAccentHeritageRed : .vnAccentImperialGold)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: VNCornerRadius.small)
                                .fill(isSelected ? Color.vnAccentRedSurface : Color.vnBackgroundPrimary)
                        )

                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        Text(cat.title)
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .foregroundColor(isSelected ? .vnAccentHeritageRed : .vnTextPrimary)
                            .lineLimit(1)
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? .vnAccentHeritageRed : .vnTextSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    if isMain {
                        Text("Chính")
                            .font(.system(size: 9, weight: .semibold, design: .serif))
                            .foregroundColor(.vnAccentHeritageRed)
                            .padding(.horizontal, VNSpacing.xs)
                            .padding(.vertical, VNSpacing.space2)
                            .background(Capsule().fill(Color.vnAccentHeritageRed.opacity(0.12)))
                    }
                }
                .padding(VNSpacing.sm)
                .background(isSelected ? Color.vnAccentRedSurface : Color.vnBackgroundTertiary)
                .clipShape(tileShape)
                .overlay(
                    tileShape
                        .stroke(isSelected ? Color.vnAccentHeritageRed : Color.vnBorderSubtle, lineWidth: VNBorderWidth.regular)
                )
            }
        )
        .buttonStyle(.plain)
    }
}
