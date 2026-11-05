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

    /// Visual height. Hit area is extended to 44pt separately (see `hitOutset`).
    public var minHeight: CGFloat {
        switch self {
        case .small: return VNSize.buttonSmall
        case .medium: return VNSize.buttonMedium
        case .large: return VNSize.buttonLarge
        }
    }

    /// Per-side expansion of the tap area so compact buttons still meet the 44pt HIG target.
    var hitOutset: CGFloat { max(0, (VNSize.minTapTarget - minHeight) / 2) }

    public var horizontalPadding: CGFloat {
        switch self {
        case .small: return VNSpacing.md
        case .medium: return VNSpacing.xl
        case .large: return VNSpacing.xxl
        }
    }

    /// Dynamic Type aware (replaces fixed 12/14/16pt sizes).
    var textStyle: Font.TextStyle {
        switch self {
        case .small: return .footnote
        case .medium: return .subheadline
        case .large: return .body
        }
    }
}

public struct VNButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
            .font(.system(size.textStyle, design: .serif, weight: .semibold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(minHeight: size.minHeight)
            .contentShape(Rectangle().inset(by: -size.hitOutset))
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
            .overlay(
                RoundedRectangle(cornerRadius: VNCornerRadius.small)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: shadowColor,
                radius: VNShadow.folio.radius,
                x: VNShadow.folio.x,
                y: VNShadow.folio.y
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .animation(
                reduceMotion ? VNAnimation.reduced : (configuration.isPressed ? VNAnimation.pressDown : VNAnimation.press),
                value: configuration.isPressed
            )
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            return .vnOnAccent
        case .gold:
            // Fixed dark ink: gold fill is light in both modes (6.9:1 light, 10.3:1 dark)
            return .vnDeepCalligraphicInk
        case .secondary:
            return .vnTextPrimary
        case .tertiary:
            return .vnAccentDeepPrimary
        }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            return isPressed ? Color.vnAccentHeritageRed.opacity(0.85) : Color.vnAccentHeritageRed
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
            return Color.vnBorderSubtle
        case .tertiary:
            return Color.clear
        }
    }

    private var borderWidth: CGFloat {
        switch variant {
        case .secondary:
            return VNBorderWidth.hairline
        default:
            return 0
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .primary:
            return Color.vnAccentHeritageRed.opacity(0.15)
        case .gold:
            return Color.vnAccentImperialGold.opacity(0.15)
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

    @State private var tapCount = 0

    public var body: some View {
        Button(
            action: {
                tapCount += 1
                action()
            },
            label: {
                HStack(spacing: VNSpacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size.textStyle, weight: .bold))
                    }
                    Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
        )
        .buttonStyle(VNButtonStyle(variant: variant, size: size, isFullWidth: isFullWidth))
        .vnImpactFeedback(trigger: tapCount)
    }
}
