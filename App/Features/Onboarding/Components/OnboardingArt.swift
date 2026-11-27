import SwiftUI
import VNCalendarDesignSystem

/// Prototype `.art-panel`: lunar-night card with a slowly turning bronze-drum motif and centred artwork.
struct OnboardingArtPanel<Content: View>: View {
    let height: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.vnNight
            LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            DrumMotif()
                .stroke(Color.vnAccentImperialGold, lineWidth: 1.4)
                .frame(width: 300, height: 300)
                .opacity(0.3)
                .vnSpinSlow(duration: 90) // prototype `drum-turn`
            content.padding(VNSpacing.xl)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
        .shadow(
            color: VNShadow.folio.color, radius: VNShadow.folio.radius,
            x: VNShadow.folio.x, y: VNShadow.folio.y
        )
    }
}

/// Simplified Dong Son drum face: concentric rings plus a ring of radial ticks.
private struct DrumMotif: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        for factor in [1.0, 0.82, 0.6, 0.38, 0.16] {
            let radius = outer * factor
            path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        }
        for tick in 0..<24 {
            let angle = Double(tick) / 24 * 2 * .pi
            let (sine, cosine) = (CGFloat(sin(angle)), CGFloat(cos(angle)))
            path.move(to: CGPoint(x: center.x + cosine * outer * 0.6, y: center.y + sine * outer * 0.6))
            path.addLine(to: CGPoint(x: center.x + cosine * outer * 0.82, y: center.y + sine * outer * 0.82))
        }
        return path
    }
}

// MARK: - Page artwork

private struct OnboardingMoon: View {
    let symbol: String
    let size: CGFloat

    var body: some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(Color.vnAccentImperialGold)
            .vnMoonGlow()
    }
}

/// Page 1: full moon over the An Nien seal.
struct OnboardingMoonArt: View {
    var body: some View {
        VStack(spacing: VNSpacing.md) {
            OnboardingMoon(symbol: "moonphase.full.moon", size: 76)
            VNSealBadge(
                text: String(localized: "onboarding.art.seal"),
                shape: .rounded(),
                color: .custom(
                    background: Color.vnNight.opacity(0.35),
                    foreground: .vnAccentImperialGold,
                    border: .vnAccentImperialGold
                ),
                size: .large
            )
        }
    }
}

/// Page 2: a mini tear-off calendar sheet.
struct OnboardingBlocArt: View {
    var body: some View {
        VStack(spacing: 0) {
            Text(String(localized: "onboarding.art.bloc_strip").uppercased())
                .font(.vnCaption2)
                .tracking(0.9)
                .foregroundStyle(Color.vnOnAccent)
                .frame(maxWidth: .infinity)
                .padding(VNSpacing.sm)
                .background(Color.vnAccentHeritageRed)
            Text(verbatim: "29")
                .font(.vnHeroNumeral)
                .foregroundStyle(Color.vnAccentHeritageRed)
            HStack(spacing: VNSpacing.xs) {
                OnboardingMoon(symbol: "moonphase.waning.gibbous", size: 16)
                Text(String(localized: "onboarding.art.bloc_lunar"))
                    .font(.vnCaption1)
                    .foregroundStyle(Color.vnTextSecondary)
            }
            .padding(.horizontal, VNSpacing.sm)
            .padding(.bottom, VNSpacing.md)
        }
        .frame(width: 150)
        .background(Color.vnBackgroundSecondary)
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 16, y: 16)
    }
}

/// Page 3: the staggered reminder pills.
struct OnboardingReminderArt: View {
    private let pills: [(title: String, offset: CGFloat)] = [
        (String(localized: "onboarding.art.pill_14"), 0),
        (String(localized: "onboarding.art.pill_3"), 18),
        (String(localized: "onboarding.art.pill_day"), -14)
    ]

    var body: some View {
        VStack(spacing: VNSpacing.sm) {
            ForEach(pills.indices, id: \.self) { position in
                HStack(spacing: VNSpacing.sm) {
                    Image(systemName: "bell.fill").foregroundStyle(Color.vnAccentHeritageRed)
                    Text(pills[position].title)
                }
                .font(.vnFootnote.weight(.semibold))
                .foregroundStyle(Color.vnNight)
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, 6)
                .frame(minHeight: 36)
                .background(Color.vnOnNight.opacity(0.92), in: .capsule)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 8)
                .offset(x: pills[position].offset)
            }
        }
    }
}
