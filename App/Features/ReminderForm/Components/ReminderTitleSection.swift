import SwiftUI
import VNCalendarDesignSystem

struct ReminderTitleSection: View {
    @Binding var title: String
    @Binding var relationship: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text("TÊN NGÀY GIỖ / SỰ KIỆN *")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.66)
                .foregroundColor(.vnAccentImperialGold)

            VNCard(
                allPadding: VNSpacing.xl,
                cornerRadius: VNCornerRadius.card,
                backgroundColor: Color.vnBackgroundSecondary,
                borderColor: Color.vnAccentImperialGold.opacity(0.28),
                shadow: nil
            ) {
                VStack(alignment: .leading, spacing: VNSpacing.md) {
                    VStack(alignment: .leading, spacing: 0) {
                        TextField("VD: Giỗ Cụ Cố Nội, Sinh nhật Mẹ...", text: $title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.vnTextPrimary)
                            .focused($isFocused)
                            .submitLabel(.done)
                            .padding(.bottom, VNSpacing.sm)
                        Rectangle()
                            .fill(isFocused ? Color.vnAccentHeritageRed : Color.vnBorderSubtle)
                            .frame(height: isFocused ? VNBorderWidth.active : VNBorderWidth.hairline)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: VNSpacing.xs) {
                            Text("Vai vế:")
                                .font(.system(size: 12))
                                .foregroundColor(.vnTextSecondary)

                            let roles = ["Nội Tộc", "Ngoại Tộc", "Cụ", "Ông", "Bà", "Cha / Bố", "Mẹ", "Bác", "Chú", "Cô", "Dì", "Anh / Chị"]
                            ForEach(roles, id: \.self) { role in
                                roleChip(role: role)
                            }
                        }
                    }
                }
            }
        }
    }

    private func roleChip(role: String) -> some View {
        let isSelected = relationship == role
        return Button(
            action: {
                relationship = role
                if title.isEmpty {
                    title = "Giỗ \(role)"
                }
            },
            label: {
                Text(role)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .vnAccentDeepPrimary : .vnTextSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isSelected ? Color.vnAccentRedSurface : Color.clear)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            isSelected ? Color.vnAccentDeepPrimary : Color.vnBorderSubtle,
                            lineWidth: VNBorderWidth.regular
                        )
                    )
            }
        )
    }
}
