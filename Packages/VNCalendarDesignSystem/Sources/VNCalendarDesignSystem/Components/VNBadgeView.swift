import SwiftUI

public struct VNBadgeView: View {
    public enum Style: Sendable {
        case rounded(cornerRadius: CGFloat = VNCornerRadius.small)
        case capsule
        case ribbon(accentColor: Color, edge: Edge = .leading, width: CGFloat = 3)
    }

    public let text: String
    public let style: Style
    public let backgroundColor: Color
    public let textColor: Color

    public init(
        text: String,
        style: Style = .rounded(),
        backgroundColor: Color = Color.vnBackgroundSecondary,
        textColor: Color = Color.vnTextPrimary
    ) {
        self.text = text
        self.style = style
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }

    public var body: some View {
        switch style {
        case .rounded(let radius):
            Text(text)
                .font(.vnCaption2)
                .fontWeight(.medium)
                .tracking(0.66)
                .foregroundColor(textColor)
                .padding(.horizontal, VNSpacing.sm)
                .padding(.vertical, VNSpacing.xs)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: radius))
                .accessibilityElement(children: .combine)
        case .capsule:
            Text(text)
                .font(.vnCaption2)
                .fontWeight(.medium)
                .tracking(0.66)
                .foregroundColor(textColor)
                .padding(.horizontal, VNSpacing.sm)
                .padding(.vertical, VNSpacing.xs)
                .background(backgroundColor)
                .clipShape(Capsule())
                .accessibilityElement(children: .combine)
        case .ribbon(let accentColor, let edge, let ribbonWidth):
            HStack(spacing: VNSpacing.xs) {
                if edge == .leading {
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: ribbonWidth)
                }
                Text(text)
                    .font(.vnCaption2)
                    .fontWeight(.medium)
                    .tracking(0.66)
                    .foregroundColor(textColor)
                    .padding(.horizontal, VNSpacing.xs)
                    .padding(.vertical, VNSpacing.xs)
                if edge == .trailing {
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: ribbonWidth)
                }
            }
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
            .accessibilityElement(children: .combine)
        }
    }
}
