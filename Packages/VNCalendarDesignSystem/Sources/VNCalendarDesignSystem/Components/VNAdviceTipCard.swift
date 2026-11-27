import SwiftUI

/// Horizontally scrolling advice card from the prototype's `.tip-card` carousel.
///
/// 208pt wide, 20pt radius, a 40pt tinted icon tile, an uppercase kicker,
/// a bold title and two lines of guidance.
public struct VNAdviceTipCard: View {
    public enum Tone: Sendable {
        case ochre, jade, blue, grey

        var foreground: Color {
            switch self {
            case .ochre: .vnAccentGoldText
            case .jade: .vnAccentJade
            case .blue: .vnAccentSky
            case .grey: .vnTextSecondary
            }
        }

        var background: Color {
            switch self {
            case .ochre: .vnAccentGoldSurface
            case .jade: .vnAccentJadeSurface
            case .blue: .vnAccentSkySurface
            case .grey: .vnBackgroundTertiary
            }
        }
    }

    public struct Model: Identifiable, Sendable {
        public let tone: Tone
        public let icon: String
        public let kicker: String
        public let title: String
        public let text: String

        public var id: String { "\(kicker)-\(title)" }

        public init(tone: Tone, icon: String, kicker: String, title: String, text: String) {
            self.tone = tone
            self.icon = icon
            self.kicker = kicker
            self.title = title
            self.text = text
        }
    }

    public let card: Model
    /// Position in the carousel; staggers the icon pop by 70ms like the prototype.
    public let index: Int

    public init(card: Model, index: Int = 0) {
        self.card = card
        self.index = index
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            iconTile
                .padding(.bottom, VNSpacing.xs)

            Text(card.kicker.uppercased())
                .font(.vnDisplay(.caption2, weight: .semibold))
                .tracking(0.8)
                .foregroundColor(.vnTextSecondary)

            Text(card.title)
                .font(.vnDisplay(.headline, weight: .bold))
                .foregroundColor(.vnTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(card.text)
                .font(.vnDisplay(.footnote))
                .foregroundColor(.vnTextSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 208, alignment: .leading)
        .padding(VNSpacing.lg)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Animated icon (`.ico` + `ico-pop`, `glow`, per-icon idle motion)

    private var iconTile: some View {
        ZStack {
            Circle()
                .fill(card.tone.foreground.opacity(0.35))
                .frame(width: 28, height: 28)
                .vnGlowPulse()

            animatedIcon
        }
        .frame(width: 40, height: 40)
        .background(card.tone.background)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small, style: .continuous))
        .vnIconPop(delay: Double(index) * 0.07)
        .accessibilityHidden(true)
    }

    /// Each advice symbol keeps its own short idle beat, as in the prototype:
    /// star twinkles, leaf sways, sun turns slowly, moon bobs.
    @ViewBuilder
    private var animatedIcon: some View {
        switch card.icon {
        case "star.fill":
            baseIcon.vnTwinkle()
        case "leaf.fill":
            baseIcon.vnSway(anchor: .bottomLeading)
        case "sun.max.fill":
            baseIcon.vnSpinSlow()
        case "moon.stars.fill":
            baseIcon.vnBob()
        default:
            baseIcon
        }
    }

    private var baseIcon: some View {
        Image(systemName: card.icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(card.tone.foreground)
    }
}
