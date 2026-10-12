import SwiftUI

public struct VNHourBranchItem: Identifiable, Sendable, Equatable {
    public let id: Int // 0..11
    public let name: String
    public let timeRange: String
    public let isAuspicious: Bool
    public let isCurrent: Bool

    public init(id: Int, name: String, timeRange: String, isAuspicious: Bool, isCurrent: Bool = false) {
        self.id = id
        self.name = name
        self.timeRange = timeRange
        self.isAuspicious = isAuspicious
        self.isCurrent = isCurrent
    }
}

public struct VN12HourTimelineView: View {
    public let hours: [VNHourBranchItem]
    public var onSelectHour: (VNHourBranchItem) -> Void

    public init(
        hours: [VNHourBranchItem],
        onSelectHour: @escaping (VNHourBranchItem) -> Void = { _ in }
    ) {
        self.hours = hours
        self.onSelectHour = onSelectHour
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            HStack(spacing: VNSpacing.xs) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.vnAccentImperialGold)

                Text("12 CANH GIỜ HOÀNG / HẮC ĐẠO")
                    .font(.vnCaption2)
                    .fontWeight(.bold)
                    .foregroundColor(.vnTextSecondary)
                    .tracking(0.6)

                Spacer()

                Text("Vàng: Hoàng Đạo")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.vnAccentImperialGold)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: VNSpacing.sm) {
                    ForEach(hours) { item in
                        Button {
                            onSelectHour(item)
                        } label: {
                            hourCell(item)
                        }
                        .buttonStyle(VNCellPressButtonStyle())
                        .accessibilityLabel(hourAccessibilityLabel(item))
                    }
                }
                .padding(.vertical, VNSpacing.space2)
            }
        }
    }

    private func hourCell(_ item: VNHourBranchItem) -> some View {
        VStack(spacing: VNSpacing.space2) {
            if item.isAuspicious {
                Circle()
                    .fill(Color.vnAccentImperialGold)
                    .frame(width: VNSpacing.xs, height: VNSpacing.xs)
            }
            Text(item.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.vnAccentHeritageRed)

            Text(item.timeRange)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.vnTextTertiary)
        }
        .padding(.horizontal, VNSpacing.sm)
        .padding(.vertical, VNSpacing.xs)
        .frame(minWidth: 56, minHeight: 44)
        .background(Color.vnBackgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.small)
                .strokeBorder(item.isCurrent ? Color.vnAccentHeritageRed : Color.vnBorderSubtle,
                              lineWidth: item.isCurrent ? VNBorderWidth.active : VNBorderWidth.hairline)
        )
        .contentShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
    }

    private func hourAccessibilityLabel(_ item: VNHourBranchItem) -> String {
        "Giờ \(item.name), \(item.timeRange) giờ, \(item.isAuspicious ? "Hoàng đạo" : "Hắc đạo")"
    }
}
