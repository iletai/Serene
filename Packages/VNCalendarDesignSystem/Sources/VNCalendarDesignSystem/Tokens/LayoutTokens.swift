import SwiftUI

public enum VNSpacing {
    public static let space2: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let space32: CGFloat = 32
    /// Golden-ratio hero gap ≈ 20 × 1.618 = 32.36, rounded to 32pt (DESIGN §4 intentional golden-ratio proportions).
    public static let golden: CGFloat = 32
    public static let hero: CGFloat = 48
    public static let screenMargin: CGFloat = 20
    public static let cardPadding: CGFloat = 16
    public static let sectionGap: CGFloat = 24
}

public enum VNSize {
    /// HIG minimum tap target.
    public static let minTapTarget: CGFloat = 44
    public static let iconButton: CGFloat = 40
    public static let iconBadge: CGFloat = 24
    /// Visual button heights. Hit area stays >= `minTapTarget` via contentShape, so compact buttons do not look "fat".
    public static let buttonSmall: CGFloat = 36
    public static let buttonMedium: CGFloat = 46
    public static let buttonLarge: CGFloat = 56
}

public enum VNLayout {
    public static let tabBarMaxWidth: CGFloat = 520
    public static let tabBarBottomInset: CGFloat = 12
    public static let tabBarItemHeight: CGFloat = 44
}

public enum VNCornerRadius {
    /// Accent bars, legend swatches, ribbons, the Hắc Đạo tag.
    public static let micro: CGFloat = 6
    /// Grid cells, hour cells, icon tiles, rounded seals.
    public static let small: CGFloat = 12
    /// Cards, group cards, panels.
    public static let card: CGFloat = 20
    /// Bottom sheets and modals.
    public static let sheet: CGFloat = 32
    public static let pill: CGFloat = 999
}

public enum VNBorderWidth {
    /// Canonical border: 1px hairline (DESIGN §4).
    public static let hairline: CGFloat = 1.0
    /// Sub-pixel hairline for the rare divider that must read thinner than 1px.
    public static let hairlineThin: CGFloat = 0.5
    /// Secondary button, field outline at rest, the seal's inner ring.
    public static let regular: CGFloat = 1.5
    /// Focused field, current hour, selected card.
    public static let active: CGFloat = 2.0
    /// Keyboard focus ring, offset 2pt.
    public static let focus: CGFloat = 3.0
}

public enum VNShadow {
    // Cool ink-tinted shadows (#15162B) plus one hard lip under pressable pills.
    public static let card = ShadowConfig(color: ink.opacity(0.08), radius: 6, x: 0, y: 2)
    /// Red glow under the hero card and the primary CTA.
    public static let warmDiffuse = ShadowConfig(color: Color(hex: 0xCC1636).opacity(0.22), radius: 32, x: 0, y: 12)
    public static let floating = ShadowConfig(color: ink.opacity(0.16), radius: 32, x: 0, y: 12)
    /// Default card shadow `0 8px 24px rgba(21,22,43,0.08)`.
    public static let folio = ShadowConfig(color: ink.opacity(0.08), radius: 24, x: 0, y: 8)
    public static let modal = ShadowConfig(color: ink.opacity(0.20), radius: 48, x: 0, y: 20)
    /// Hard 4pt ledge under pressable pills; it disappears as the pill presses down.
    public static let lip = ShadowConfig(
        color: Color(light: ink.opacity(0.22), dark: Color.black.opacity(0.5)), radius: 0, x: 0, y: 4
    )

    private static let ink = Color(hex: 0x15162B)

    public struct ShadowConfig: Sendable {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat

        public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }
    }
}
