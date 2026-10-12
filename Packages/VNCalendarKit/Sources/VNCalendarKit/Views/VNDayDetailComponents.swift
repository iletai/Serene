import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

// MARK: - Day Evaluation Subview

struct VNDayEvaluationView: View {
    let dayModel: VNCalendarDayModel

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            HStack(spacing: VNSpacing.xs) {
                Image(systemName: dayModel.isAuspiciousDay ? "sparkles" : "circle.circle")
                    .foregroundColor(dayModel.isAuspiciousDay ? .vnAccentImperialGold : .vnTextSecondary)
                    .font(.system(size: 14, weight: .semibold))

                Text(dayModel.zodiacStar.fullTitle)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(dayModel.isAuspiciousDay ? .vnStatusSuccess : .vnTextPrimary)

                Spacer()

                Text(dayModel.lunarOfficer.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.vnAccentHeritageRed)
                    .padding(.horizontal, VNSpacing.sm)
                    .padding(.vertical, VNSpacing.space2)
                    .background(Color.vnAccentHeritageRed.opacity(0.1))
                    .clipShape(Capsule())
            }

            Divider().background(Color.vnBorderSubtle)

            HStack(alignment: .top, spacing: VNSpacing.xs) {
                Text("Trực:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.vnTextSecondary)

                Text(dayModel.lunarOfficer.summary)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.vnTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let term = dayModel.solarTermName {
                HStack(alignment: .top, spacing: VNSpacing.xs) {
                    Text("Tiết khí:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.vnTextSecondary)

                    Text("Tiết \(term) — Khí tiết bản địa phương Nam")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.vnTextPrimary)
                }
            }
        }
        .padding(VNSpacing.xl)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
    }
}

// MARK: - Auspicious Directions Subview

struct VNDayDirectionsView: View {
    let dayModel: VNCalendarDayModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HƯỚNG XUẤT HÀNH CÁT LỢI")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.vnTextSecondary)
                .tracking(0.5)

            HStack(spacing: VNSpacing.md) {
                directionPill(title: "Hỷ Thần (May Mắn)", direction: dayModel.joyGodDirection, color: .vnAccentHeritageRed)
                directionPill(title: "Tài Thần (Tài Lộc)", direction: dayModel.wealthGodDirection, color: .vnAccentImperialGold)
            }
        }
    }

    private func directionPill(title: String, direction: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.vnTextSecondary)
                Text(direction)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(VNSpacing.sm)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
    }
}

// MARK: - Activities Subview

struct VNDayActivitiesView: View {
    let dayModel: VNCalendarDayModel

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text("VIỆC NÊN LÀM & KIÊNG CỮ")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.vnTextSecondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: 8) {
                activityRow(
                    icon: "checkmark.circle.fill",
                    label: "Nên làm:",
                    color: .vnStatusSuccess,
                    content: dayModel.suitableActivities.joined(separator: " • "),
                    contentColor: .vnTextPrimary
                )

                Divider().background(Color.vnBorderSubtle.opacity(0.6))

                activityRow(
                    icon: "xmark.circle.fill",
                    label: "Kiêng cữ:",
                    color: .vnStatusError,
                    content: dayModel.tabooActivities.joined(separator: " • "),
                    contentColor: .vnTextSecondary
                )
            }
            .padding(VNSpacing.xl)
            .background(Color.vnBackgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: VNCornerRadius.card)
                    .stroke(Color.vnBorderSubtle.opacity(0.6), lineWidth: VNBorderWidth.hairline)
            )
        }
    }

    private func activityRow(icon: String, label: String, color: Color, content: String, contentColor: Color) -> some View {
        HStack(alignment: .top, spacing: VNSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)

                Text(content)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(contentColor)
            }
        }
    }
}
