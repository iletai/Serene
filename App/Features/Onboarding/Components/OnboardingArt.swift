import SwiftUI
import VNCalendarDesignSystem

// MARK: - Page artwork

/// Page 1: full moon over the An Nien seal.
struct OnboardingMoonArt: View {
    var body: some View {
        VStack(spacing: VNSpacing.md) {
            VNMoonDisc(lunarDay: 15, size: 76, onArt: true).vnMoonGlow()
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
                VNMoonDisc(lunarDay: 19, size: 16)
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
