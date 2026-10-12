import SwiftUI

/// Consistent elevated container card embodying the "Vietnamese Lunar Editorial" aesthetic.
/// Employs .vnBackgroundSecondary, hairline border .vnBorderSubtle, and gentle warm diffuse shadow.
public struct VNCard<Content: View>: View {
    public let content: Content
    public let cornerRadius: CGFloat
    public let backgroundColor: Color
    public let borderColor: Color
    public let borderWidth: CGFloat
    public let padding: EdgeInsets
    public let shadow: VNShadow.ShadowConfig?

    /// Canonical structural card radius — DESIGN §4 structural cards (8pt).
    /// Computed (not stored) because static stored properties are unsupported in generic types.
    public static var defaultCornerRadius: CGFloat { VNCornerRadius.card }

    /// Faint folio shadow `0 4px 20px -2px rgba(90,84,79,0.05)`. Reuses VNShadow.folio.
    public static var folioShadow: VNShadow.ShadowConfig { VNShadow.folio }

    public init(
        cornerRadius: CGFloat = VNCard.defaultCornerRadius,
        backgroundColor: Color = Color.vnBackgroundSecondary,
        borderColor: Color = Color.vnAccentImperialGold.opacity(0.28),
        borderWidth: CGFloat = VNBorderWidth.hairline,
        padding: EdgeInsets = EdgeInsets(
            top: VNSpacing.xl,
            leading: VNSpacing.xl,
            bottom: VNSpacing.xl,
            trailing: VNSpacing.xl
        ),
        shadow: VNShadow.ShadowConfig? = VNCard.folioShadow,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.padding = padding
        self.shadow = shadow
        self.content = content()
    }

    public init(
        allPadding: CGFloat,
        cornerRadius: CGFloat = VNCard.defaultCornerRadius,
        backgroundColor: Color = Color.vnBackgroundSecondary,
        borderColor: Color = Color.vnAccentImperialGold.opacity(0.28),
        borderWidth: CGFloat = VNBorderWidth.hairline,
        shadow: VNShadow.ShadowConfig? = VNCard.folioShadow,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            borderWidth: borderWidth,
            padding: EdgeInsets(top: allPadding, leading: allPadding, bottom: allPadding, trailing: allPadding),
            shadow: shadow,
            content: content
        )
    }

    public var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: cornerRadius)

        let baseCard = content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(cardShape)
            .overlay(
                cardShape
                    .stroke(borderColor, lineWidth: borderWidth)
            )

        if let shadow {
            baseCard.shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
        } else {
            baseCard
        }
    }
}
