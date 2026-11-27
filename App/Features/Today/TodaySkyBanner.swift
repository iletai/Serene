import SwiftUI
import VNCalendarDesignSystem

/// Season photo hero above the Today bloc (design.html `.sky`): eyebrow, title and the season pill in white
/// over a sky-shade, with the bronze-drum motif turning behind.
struct TodaySkyBanner: View {
    let season: ArtSeason
    let eyebrow: String

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            Text(verbatim: eyebrow)
                .font(.vnDisplay(.footnote, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.86))
            Text("today.hero.title")
                .font(.vnDisplay(.title, weight: .bold))
                .foregroundStyle(Color.white)
                .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 6) {
                Image(systemName: "moon.fill")
                    .foregroundStyle(Color.vnAccentImperialGold)
                    .vnBob()
                    .accessibilityHidden(true)
                Text(season.label)
            }
            .font(.vnDisplay(.footnote, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, VNSpacing.md)
            .padding(.vertical, VNSpacing.xs)
            .background(Color.white.opacity(0.16), in: .capsule)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .bottomLeading)
        .padding(VNSpacing.xl)
        .background {
            ZStack(alignment: .topTrailing) {
                Color.vnNight
                ArtBackdrop(image: season.assetName)
                SkyShade()
                DrumMotif(size: 250, opacity: 0.32)
                    .offset(x: 78, y: 34)
            }
        }
        .clipShape(.rect(cornerRadius: VNCard<EmptyView>.defaultCornerRadius, style: .continuous))
        .shadow(
            color: VNShadow.folio.color, radius: VNShadow.folio.radius,
            x: VNShadow.folio.x, y: VNShadow.folio.y
        )
        .vnRise(distance: 18)
        .accessibilityElement(children: .combine)
    }
}
