import SwiftUI

/// Ấn Triện: a solid cinnabar stamp with a pale inner ring, tilted -3°, that stamps in on first appear.
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
            case .large: 14
            }
        }

        /// Canonical 44x44 seal square. Only the medium square enforces this frame.
        public static let canonicalSquareSize: CGFloat = 44

        public var paddingHorizontal: CGFloat {
            switch self {
            case .small: VNSpacing.xs
            case .medium: VNSpacing.sm
            case .large: VNSpacing.md
            }
        }

        public var paddingVertical: CGFloat {
            switch self {
            case .small: VNSpacing.space2
            case .medium: VNSpacing.xs
            case .large: VNSpacing.sm
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
        VNSealBadge(text: String(localized: "ds.seal.mung_mot"), shape: .rounded(), color: .cinnabarWhite, size: size)
    }

    /// Ấn Triện RẰM (Sơn son thếp vàng)
    public static func ram(size: Size = .medium) -> VNSealBadge {
        VNSealBadge(text: String(localized: "ds.seal.ram"), shape: .rounded(), color: .cinnabarGold, size: size)
    }

    /// Ấn Triện GIỖ (Son sẫm trang nghiêm)
    public static func gio(size: Size = .medium) -> VNSealBadge {
        VNSealBadge(text: String(localized: "ds.seal.gio"), shape: .square, color: .vermilionDarkGold, size: size)
    }

    /// Ấn Triện TẾT (Viên mãn hình khuyên)
    public static func tet(size: Size = .medium) -> VNSealBadge {
        VNSealBadge(text: String(localized: "ds.seal.tet"), shape: .pill, color: .cinnabarGold, size: size)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stampCount = 0

    private var backgroundColor: Color {
        switch color {
        case .cinnabarWhite, .cinnabarGold, .vermilionDarkGold:
            Color.vnAccentHeritageRed
        case .custom(let background, _, _):
            background
        }
    }

    private var foregroundColor: Color {
        switch color {
        case .cinnabarWhite, .cinnabarGold, .vermilionDarkGold:
            Color.vnOnAccent
        case .custom(_, let foreground, _):
            foreground
        }
    }

    public var body: some View {
        HStack(spacing: VNSpacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.vnDisplay(size: size.fontSize - 1, weight: .heavy))
            }
            Text(text)
                .font(.vnDisplay(size: size.fontSize, weight: .heavy))
                .tracking(0.6)
        }
        .foregroundColor(foregroundColor)
        .padding(.horizontal, size.paddingHorizontal)
        .padding(.vertical, size.paddingVertical)
        .frame(
            minWidth: isCanonicalSquare ? Size.canonicalSquareSize : nil,
            minHeight: isCanonicalSquare ? Size.canonicalSquareSize : nil
        )
        .background(backgroundColor)
        .clipShape(SealBadgeShape(shape: shape))
        .overlay(innerRing)
        .shadow(
            color: VNShadow.card.color,
            radius: VNShadow.card.radius,
            x: VNShadow.card.x,
            y: VNShadow.card.y
        )
        .rotationEffect(.degrees(-3))
        .keyframeAnimator(initialValue: StampFrame(), trigger: stampCount) { content, frame in
            content
                .scaleEffect(frame.scale)
                .rotationEffect(.degrees(frame.extraAngle))
                .opacity(frame.opacity)
        } keyframes: { [reduceMotion] _ in
            Self.stampKeyframes(reduceMotion: reduceMotion)
        }
        .onAppear { stampCount += 1 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "ds.seal.a11y_label"), text))
    }

    /// Stamp: lands from 190% and -18° (extra -15° on top of the resting -3°), rebounds, rests. 0.52s.
    /// Reduce Motion: fade only.
    @KeyframesBuilder<StampFrame>
    private nonisolated static func stampKeyframes(reduceMotion: Bool) -> some Keyframes<StampFrame> {
        KeyframeTrack(\.scale) {
            LinearKeyframe(reduceMotion ? 1 : 1.9, duration: 0)
            CubicKeyframe(reduceMotion ? 1 : 0.9, duration: 0.29)
            SpringKeyframe(reduceMotion ? 1 : 1.05, duration: 0.12)
            SpringKeyframe(1, duration: 0.11)
        }
        KeyframeTrack(\.extraAngle) {
            LinearKeyframe(reduceMotion ? 0 : -15, duration: 0)
            CubicKeyframe(0, duration: 0.29)
        }
        KeyframeTrack(\.opacity) {
            LinearKeyframe(0, duration: 0)
            LinearKeyframe(1, duration: 0.15)
        }
    }

    /// Pale inner ring: 1.5pt vnOnAccent at 55%, inset 3pt, the edge of the carved stone.
    private var innerRing: some View {
        SealBadgeShape(shape: shape, inset: 3)
            .stroke(foregroundColor.opacity(0.55), lineWidth: VNBorderWidth.regular)
    }

    private var isCanonicalSquare: Bool {
        shape == .square && size == .medium
    }
}

/// Resting values; the stamp keyframes jump away from these and settle back.
struct StampFrame: Sendable {
    var scale: CGFloat = 1
    var extraAngle: Double = 0
    var opacity: Double = 1
}

private struct SealBadgeShape: Shape {
    let shape: VNSealBadge.Shape
    var inset: CGFloat = 0

    func path(in fullRect: CGRect) -> Path {
        let rect = fullRect.insetBy(dx: inset, dy: inset)
        return switch shape {
        case .square:
            Path(roundedRect: rect, cornerRadius: max(0, VNCornerRadius.micro - inset))
        case .rounded(let cornerRadius):
            Path(roundedRect: rect, cornerRadius: max(0, cornerRadius - inset))
        case .pill:
            Path(roundedRect: rect, cornerRadius: rect.height / 2)
        case .circle:
            Path(ellipseIn: rect)
        }
    }
}
