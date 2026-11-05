import SwiftUI
import VNCalendarDesignSystem

struct ReminderOffsetsCard: View {
    @Binding var notifyOnDay: Bool
    @Binding var notify1DayBefore: Bool
    @Binding var notify3DaysBefore: Bool
    @Binding var notify7DaysBefore: Bool
    @Binding var notify14DaysBefore: Bool
    @Binding var notify30DaysBefore: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text("NHẮC NHỞ CHUẨN BỊ LỄ NGHI (08:00 SÁNG)")
                .font(.caption2.weight(.medium))
                .tracking(0.66)
                .foregroundColor(.vnAccentGoldText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)

            VNCard(
                allPadding: VNSpacing.cardPadding,
                cornerRadius: VNCornerRadius.card,
                backgroundColor: Color.vnBackgroundSecondary,
                borderColor: Color.vnAccentImperialGold.opacity(0.28),
                shadow: nil
            ) {
                OffsetFlowLayout(spacing: VNSpacing.xs) {
                    offsetChip(title: "Đúng ngày", subtitle: "Lễ chính", isOn: $notifyOnDay)
                    offsetChip(title: "Trước 1 ngày", subtitle: "Chuẩn bị nấu cỗ", isOn: $notify1DayBefore)
                    offsetChip(title: "Trước 3 ngày", subtitle: "Đi chợ, sắm lễ vật", isOn: $notify3DaysBefore)
                    offsetChip(title: "Trước 7 ngày", subtitle: "Họp gia đình, phân công", isOn: $notify7DaysBefore)
                    offsetChip(title: "Trước 14 ngày", subtitle: "Bàn bạc đại gia tộc", isOn: $notify14DaysBefore)
                    offsetChip(title: "Trước 30 ngày", subtitle: "Lên kế hoạch cúng giỗ", isOn: $notify30DaysBefore)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func offsetChip(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        let selected = isOn.wrappedValue
        return Button(
            action: {
                withAnimation(reduceMotion ? nil : .snappy(duration: 0.2)) { isOn.wrappedValue.toggle() }
            },
            label: {
                HStack(spacing: VNSpacing.xs) {
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .accessibilityHidden(true)
                    }
                    Text(title)
                        .font(.footnote.weight(selected ? .semibold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundColor(selected ? .vnAccentDeepPrimary : .vnTextSecondary)
                .padding(.horizontal, VNSpacing.md)
                .frame(minHeight: VNSize.buttonSmall)
                .background(selected ? Color.vnAccentRedSurface : Color.clear, in: Capsule())
                .overlay(
                    Capsule().stroke(
                        selected ? Color.vnAccentDeepPrimary : Color.vnBorderSubtle,
                        lineWidth: VNBorderWidth.regular
                    )
                )
                .frame(minHeight: VNSize.minTapTarget)
                .contentShape(Rectangle())
            }
        )
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Wraps children onto multiple rows, left-aligned, keeping each child at its ideal size.
private struct OffsetFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (origins: [CGPoint], size: CGSize) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return (origins, CGSize(width: maxX, height: y + rowHeight))
    }
}
