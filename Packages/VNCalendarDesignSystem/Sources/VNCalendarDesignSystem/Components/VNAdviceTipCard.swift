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

    public init(card: Model) {
        self.card = card
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            Image(systemName: card.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(card.tone.foreground)
                .frame(width: 40, height: 40)
                .background(card.tone.background)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small, style: .continuous))
                .padding(.bottom, VNSpacing.xs)
                .accessibilityHidden(true)

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
}
