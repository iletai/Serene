import SwiftUI

public enum VNButtonVariant: Sendable {
    case primary      // Đỏ Lồng Đèn nền đặc, chữ vnOnAccent
    case secondary    // Nền cấp 2, viền vnBorderStrong
    case tertiary     // Nền trong suốt, chữ đỏ, không có lip
    case gold         // Vàng Hoa Mai cho Pro / Lễ Tiết, chữ mực cố định
    case destructive  // Đỏ cảnh báo
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
        case .small: return 14
        case .medium: return VNSpacing.xl
        case .large: return 28
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
        let isPressed = configuration.isPressed
        return configuration.label
            .font(.vnDisplay(size.textStyle, weight: .bold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(minHeight: size.minHeight)
            .background(backgroundColor(isPressed: isPressed), in: Capsule())
            .overlay(Capsule().strokeBorder(borderColor, lineWidth: borderWidth))
            // The pill drops onto its lip when pressed; tertiary shrinks instead.
            .offset(y: hasLip && isPressed && !reduceMotion ? VNShadow.lip.y : 0)
            .scaleEffect(!hasLip && isPressed && !reduceMotion ? 0.95 : 1.0)
            .background(alignment: .top) {
                if hasLip {
                    Capsule().fill(VNShadow.lip.color).offset(y: VNShadow.lip.y)
                }
            }
            .padding(.bottom, hasLip ? VNShadow.lip.y : 0)
            .contentShape(Rectangle().inset(by: -size.hitOutset))
            .animation(
                reduceMotion ? VNAnimation.reduced : (isPressed ? VNAnimation.pressDown : VNAnimation.press),
                value: isPressed
            )
    }

    private var hasLip: Bool { variant != .tertiary }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            return .vnOnAccent
        case .gold:
            // Fixed dark ink: gold fill is light in both modes (11:1)
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
            return isPressed ? Color.vnBackgroundTertiary : Color.vnBackgroundSecondary
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
            return Color.vnBorderStrong
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
                            .font(.vnDisplay(size.textStyle, weight: .bold))
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
