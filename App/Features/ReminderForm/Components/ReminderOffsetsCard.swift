import SwiftUI
import VNCalendarDesignSystem

struct ReminderOffsetsCard: View {
    @Binding var notifyOnDay: Bool
    @Binding var notify1DayBefore: Bool
    @Binding var notify3DaysBefore: Bool
    @Binding var notify7DaysBefore: Bool
    @Binding var notify14DaysBefore: Bool
    @Binding var notify30DaysBefore: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text("NHẮC NHỞ CHUẨN BỊ LỄ NGHI (08:00 SÁNG)")
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
                VStack(spacing: VNSpacing.xs) {
                    offsetChip(title: "Đúng ngày diễn ra", subtitle: "Lễ chính", isOn: $notifyOnDay)
                    offsetChip(title: "Trước 1 ngày", subtitle: "Chuẩn bị nấu cỗ", isOn: $notify1DayBefore)
                    offsetChip(title: "Trước 3 ngày", subtitle: "Đi chợ, sắm lễ vật", isOn: $notify3DaysBefore)
                    offsetChip(title: "Trước 7 ngày", subtitle: "Họp gia đình, phân công", isOn: $notify7DaysBefore)
                    offsetChip(title: "Trước 14 ngày", subtitle: "Bàn bạc đại gia tộc", isOn: $notify14DaysBefore)
                    offsetChip(title: "Trước 30 ngày", subtitle: "Lên kế hoạch cúng giỗ", isOn: $notify30DaysBefore)
                }
            }
        }
    }

    private func offsetChip(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        let selected = isOn.wrappedValue
        return Button(
            action: { isOn.wrappedValue.toggle() },
            label: {
                HStack(spacing: VNSpacing.sm) {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(selected ? .vnAccentDeepPrimary : .vnTextSecondary)
                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selected ? .vnAccentDeepPrimary : .vnTextSecondary)
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.vnTextSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, VNSpacing.md)
                .padding(.vertical, VNSpacing.sm)
                .background(selected ? Color.vnAccentRedSurface : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        selected ? Color.vnAccentDeepPrimary : Color.vnBorderSubtle,
                        lineWidth: VNBorderWidth.regular
                    )
                )
            }
        )
        .buttonStyle(.plain)
    }
}
