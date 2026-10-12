import SwiftUI

public enum VNButtonVariant: Sendable {
    case primary      // Đỏ Son Đậm (#A0220B) nền đặc, chữ trắng
    case secondary    // Vải Xô / Nền cấp 2 viền mộc hairline
    case tertiary     // Nền trong suốt, chữ đỏ hoặc mực nho
    case gold         // Vàng Hoàng Cúc (#C69214) cho Pro / Lễ Tiết
    case destructive  // Đỏ Huyết Dụ cảnh báo
}

public enum VNButtonSize: Sendable {
    case small
    case medium
    case large

    /// HIG minimum 44pt touch target. The 36pt top bar is the sole 44-exception (DESIGN §4).
    public var minHeight: CGFloat {
        switch self {
        case .small: return 44
        case .medium: return 44
        case .large: return 52
        }
    }

    public var horizontalPadding: CGFloat {
        switch self {
        case .small: return VNSpacing.md
        case .medium: return VNSpacing.lg
        case .large: return VNSpacing.xl
        }
    }

    public var fontSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 14
        case .large: return 16
        }
    }
}

public struct VNButtonStyle: ButtonStyle {
    public let variant: VNButtonVariant
    public let size: VNButtonSize
    public let isFullWidth: Bool

    public init(
        variant: VNButtonVariant = .primary,
        size: VNButtonSize = .medium,
        isFullWidth: Bool = false
    ) {
        self.variant = variant
        self.size = size
        self.isFullWidth = isFullWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size.fontSize, weight: .semibold, design: .serif))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(minHeight: size.minHeight)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
            .overlay(
                RoundedRectangle(cornerRadius: VNCornerRadius.small)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: VNShadow.card.color,
                radius: VNShadow.card.radius,
                x: VNShadow.card.x,
                y: VNShadow.card.y
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(VNAnimation.cellSelection, value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .gold, .destructive:
            return .white
        case .secondary:
            return .vnTextPrimary
        case .tertiary:
            return .vnAccentDeepPrimary
        }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            return isPressed ? Color.vnAccentDeepPrimary.opacity(0.85) : Color.vnAccentDeepPrimary
        case .secondary:
            return isPressed ? Color.vnBackgroundTertiary : Color.clear
        case .tertiary:
            return isPressed ? Color.vnAccentRedSurface : Color.clear
        case .gold:
            return isPressed ? Color.vnAccentImperialGold.opacity(0.85) : Color.vnAccentImperialGold
        case .destructive:
            return isPressed ? Color.vnStatusError.opacity(0.85) : Color.vnStatusError
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary, .gold, .destructive:
            return Color.clear
        case .secondary:
            return Color.vnAccentImperialGold
        case .tertiary:
            return Color.clear
        }
    }

    private var borderWidth: CGFloat {
        switch variant {
        case .secondary:
            return VNBorderWidth.regular
        default:
            return 0
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .primary:
            return Color.vnAccentDeepPrimary.opacity(0.25)
        case .gold:
            return Color.vnAccentImperialGold.opacity(0.2)
        default:
            return Color.clear
        }
    }
}

public struct VNButton: View {
    public let title: String
    public let icon: String?
    public let variant: VNButtonVariant
    public let size: VNButtonSize
    public let isFullWidth: Bool
    public let action: () -> Void

    public init(
        _ title: String,
        icon: String? = nil,
        variant: VNButtonVariant = .primary,
        size: VNButtonSize = .medium,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
        self.isFullWidth = isFullWidth
        self.action = action
    }

    public var body: some View {
        Button(
            action: {
                triggerHaptic()
                action()
            },
            label: {
                HStack(spacing: VNSpacing.xs) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: size.fontSize - 1, weight: .bold))
                    }
                    Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
        )
        .buttonStyle(VNButtonStyle(variant: variant, size: size, isFullWidth: isFullWidth))
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}
