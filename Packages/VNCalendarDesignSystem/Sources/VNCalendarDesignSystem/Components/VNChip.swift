import SwiftUI

public enum VNChipVariant: Sendable {
    case solarTerm    // Tiết khí (Nền vàng hoàng cúc nhạt, chữ vàng quỳ)
    case auspicious   // Hoàng đạo (Nền xanh lá tre nhạt, chữ xanh)
    case inauspicious // Hắc đạo (Nền xám tro nhạt, chữ tro trầm)
    case heritage     // Đỏ Son Chu Sa (Nền son nhạt, chữ son)
    case custom(background: Color, foreground: Color, border: Color?)
}

public struct VNChip: View {
    public let text: String
    public let icon: String?
    public let variant: VNChipVariant

    public init(
        _ text: String,
        icon: String? = nil,
        variant: VNChipVariant = .solarTerm
    ) {
        self.text = text
        self.icon = icon
        self.variant = variant
    }

    public var body: some View {
        HStack(spacing: VNSpacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.vnCellSolarTerm)
                    .foregroundColor(foregroundColor)
            }
            Text(text)
                .font(.vnCaption2)
                .fontWeight(.medium)
                .tracking(0.66)
                .foregroundColor(foregroundColor)
                .lineLimit(1)
        }
        .padding(.horizontal, VNSpacing.sm)
        .padding(.vertical, VNSpacing.xs)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(borderColor, lineWidth: VNBorderWidth.hairlineThin)
        )
        .accessibilityElement(children: .combine)
    }

    private var foregroundColor: Color {
        switch variant {
        case .solarTerm, .auspicious:
            return .vnOnGoldContainer
        case .inauspicious:
            return .vnTextSecondary
        case .heritage:
            return .vnAccentDeepPrimary
        case .custom(_, let fg, _):
            return fg
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .solarTerm, .auspicious:
            return Color.vnGoldContainer
        case .inauspicious:
            return Color.vnBackgroundTertiary
        case .heritage:
            return Color.vnAccentRedSurface
        case .custom(let bg, _, _):
            return bg
        }
    }

    private var borderColor: Color {
        switch variant {
        case .solarTerm, .auspicious:
            return Color.vnAccentImperialGold.opacity(0.35)
        case .inauspicious:
            return Color.vnBorderSubtle
        case .heritage:
            return Color.vnAccentHeritageRed.opacity(0.25)
        case .custom(_, _, let border):
            return border ?? Color.clear
        }
    }
}
