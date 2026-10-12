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
}

public enum VNCornerRadius {
    public static let small: CGFloat = 4
    public static let medium: CGFloat = 10
    public static let card: CGFloat = 8
    public static let large: CGFloat = 16
    public static let sheet: CGFloat = 24
    public static let pill: CGFloat = 999
}

public enum VNBorderWidth {
    /// Canonical border: 1px hairline (DESIGN §4).
    public static let hairline: CGFloat = 1.0
    /// Sub-pixel hairline for the rare divider that must read thinner than 1px.
    public static let hairlineThin: CGFloat = 0.5
    public static let regular: CGFloat = 1.0
    public static let active: CGFloat = 1.5
    public static let focus: CGFloat = 2.0
}

public enum VNShadow {
    public static let card = ShadowConfig(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    public static let warmDiffuse = ShadowConfig(color: Color.vnAccentHeritageRed.opacity(0.06), radius: 16, x: 0, y: 6)
    public static let floating = ShadowConfig(color: Color.vnAccentHeritageRed.opacity(0.08), radius: 12, x: 0, y: 6)
    /// Faint folio shadow `0 4px 20px -2px rgba(90,84,79,0.05)` (DESIGN §4). Spread omitted: SwiftUI has no spread param.
    public static let folio = ShadowConfig(color: Color(hex: 0x5A544F).opacity(0.05), radius: 20, x: 0, y: 4)
    /// Soft modal shadow honoring "no heavy shadows" (DESIGN §4).
    public static let modal = ShadowConfig(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)

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
