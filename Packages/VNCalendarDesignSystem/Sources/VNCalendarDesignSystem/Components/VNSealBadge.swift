import SwiftUI

/// Traditional Vietnamese debossed wax seal (Ấn Triện) component.
/// Embodies the "Vietnamese Lunar Editorial" aesthetic with authentic cinnabar and gold pigments.
public struct VNSealBadge: View {
    public enum Shape: Sendable, Equatable {
        case square
        case rounded(cornerRadius: CGFloat = VNCornerRadius.small)
        case pill
        case circle
    }

    public enum SealColor: Sendable, Equatable {
        case cinnabarWhite
        case cinnabarGold
        case vermilionDarkGold
        case custom(background: Color, foreground: Color, border: Color? = nil)
    }

    public enum Size: Sendable, Equatable {
        case small
        case medium
        case large

        public var fontSize: CGFloat {
            switch self {
            case .small: 9
            case .medium: 11
            case .large: 13
            }
        }

        public var paddingHorizontal: CGFloat {
            switch self {
            case .small: VNSpacing.xs + 2
            case .medium: VNSpacing.sm
            case .large: VNSpacing.md
            }
        }

        public var paddingVertical: CGFloat {
            switch self {
            case .small: 2
            case .medium: 4
            case .large: 6
            }
        }
    }

    public let text: String
    public let icon: String?
    public let shape: Shape
    public let color: SealColor
    public let size: Size

    public init(
        text: String,
        icon: String? = nil,
        shape: Shape = .rounded(),
        color: SealColor = .cinnabarWhite,
        size: Size = .medium
    ) {
        self.text = text
        self.icon = icon
        self.shape = shape
        self.color = color
        self.size = size
    }

    // MARK: - Convenience Factory Initializers

    /// Ấn Triện MÙNG 1 (Sơn son thiếp trắng)
    public static func mungMot(size: Size = .medium) -> VNSealBadge {
        VNSealBadge(text: "MÙNG 1", shape: .rounded(), color: .cinnabarWhite, size: size)
    }

    /// Ấn Triện RẰM (Sơn son thếp vàng)
    public static func ram(size: Size = .medium) -> VNSealBadge {
        VNSealBadge(text: "RẰM", shape: .rounded(), color: .cinnabarGold, size: size)
    }

    /// Ấn Triện GIỖ (Son sẫm trang nghiêm)
    public static func gio(size: Size = .medium) -> VNSealBadge {
        VNSealBadge(text: "GIỖ", shape: .square, color: .vermilionDarkGold, size: size)
    }

    /// Ấn Triện TẾT (Viên mãn hình khuyên)
    public static func tet(size: Size = .medium) -> VNSealBadge {
        VNSealBadge(text: "TẾT", shape: .pill, color: .cinnabarGold, size: size)
    }

    private var backgroundColor: Color {
        switch color {
        case .cinnabarWhite, .cinnabarGold, .vermilionDarkGold:
            Color.vnBackgroundPrimary
        case .custom(let background, _, _):
            background
        }
    }

    private var foregroundColor: Color {
        switch color {
        case .cinnabarWhite, .cinnabarGold, .vermilionDarkGold:
            Color.vnAccentHeritageRed
        case .custom(_, let foreground, _):
            foreground
        }
    }

    private var borderColor: Color {
        switch color {
        case .cinnabarWhite, .cinnabarGold, .vermilionDarkGold:
            Color.vnAccentHeritageRed
        case .custom(_, _, let border):
            border ?? Color.clear
        }
    }

    public var body: some View {
        HStack(spacing: VNSpacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: size.fontSize - 1, weight: .bold))
            }
            Text(text)
                .font(.system(size: size.fontSize, weight: .bold, design: .serif))
                .tracking(0.6)
        }
        .foregroundColor(foregroundColor)
        .padding(.horizontal, size.paddingHorizontal)
        .padding(.vertical, size.paddingVertical)
        .frame(minWidth: isCanonicalSquare ? 40 : nil, minHeight: isCanonicalSquare ? 40 : nil)
        .background(backgroundColor)
        .clipShape(SealBadgeShape(shape: shape))
        .overlay(shapeStroke)
        .overlay(insetRing)
        .shadow(
            color: Color.vnAccentHeritageRed.opacity(0.15),
            radius: VNShadow.card.radius,
            x: VNShadow.card.x,
            y: VNShadow.card.y
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ấn triện \(text)")
    }

    /// Canonical seal: 2pt outer border on the medium square, 1pt elsewhere (DESIGN §4).
    private var shapeStroke: some View {
        SealBadgeShape(shape: shape)
            .stroke(borderColor,
                    lineWidth: isCanonicalSquare ? VNBorderWidth.focus : VNBorderWidth.regular)
    }

    /// Inset ring: `inset 0 0 0 1px rgba(160,34,11,0.4)` from `.seal-shadow`.
    @ViewBuilder
    private var insetRing: some View {
        switch shape {
        case .square:
            Rectangle()
                .inset(by: 1)
                .stroke(Color.vnAccentHeritageRed.opacity(0.4), lineWidth: VNBorderWidth.regular)
        case .rounded(let radius):
            RoundedRectangle(cornerRadius: max(0, radius - 1))
                .inset(by: 1)
                .stroke(Color.vnAccentHeritageRed.opacity(0.4), lineWidth: VNBorderWidth.regular)
        case .pill:
            Capsule()
                .inset(by: 1)
                .stroke(Color.vnAccentHeritageRed.opacity(0.4), lineWidth: VNBorderWidth.regular)
        case .circle:
            Circle()
                .inset(by: 1)
                .stroke(Color.vnAccentHeritageRed.opacity(0.4), lineWidth: VNBorderWidth.regular)
        }
    }

    private var isCanonicalSquare: Bool {
        shape == .square && size == .medium
    }
}

private struct SealBadgeShape: Shape {
    let shape: VNSealBadge.Shape

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .square:
            Path(rect)
        case .rounded(let cornerRadius):
            Path(roundedRect: rect, cornerRadius: cornerRadius)
        case .pill:
            Path(roundedRect: rect, cornerRadius: rect.height / 2)
        case .circle:
            Path(ellipseIn: rect)
        }
    }
}
