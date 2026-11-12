import SwiftUI
import VNCalendarDesignSystem

struct MemorialTimelineDivider: View {
    let title: String

    var body: some View {
        HStack(spacing: VNSpacing.sm) {
            Rectangle()
                .fill(Color.vnBorderSubtle)
                .frame(height: VNBorderWidth.hairline)

            HStack(spacing: VNSpacing.xs) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .accessibilityHidden(true)
                    .foregroundColor(.vnAccentImperialGold)

                Text(title)
                    .font(.vnDisplay(.caption, weight: .semibold))
                    .foregroundColor(.vnTextSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, VNSpacing.xs)

            Rectangle()
                .fill(Color.vnBorderSubtle)
                .frame(height: VNBorderWidth.hairline)
        }
        .padding(.vertical, VNSpacing.xs)
    }
}
