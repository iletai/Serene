import SwiftUI
import VNCalendarDesignSystem

/// Seasonal photo set from design.html (`seasonOf`). Images live in `Assets.xcassets/Season`.
enum ArtSeason: String, CaseIterable {
    case spring, summer, autumn, winter, lantern

    var assetName: String { "Season/\(rawValue)" }

    var label: LocalizedStringKey {
        switch self {
        case .spring: "art.season.spring"
        case .summer: "art.season.summer"
        case .autumn: "art.season.autumn"
        case .winter: "art.season.winter"
        case .lantern: "art.season.lantern"
        }
    }

    /// Mid-autumn and Tet windows follow the lunar date; every other day follows the solar month.
    static func of(solarMonth: Int, lunarMonth: Int, lunarDay: Int) -> ArtSeason {
        if lunarMonth == 8, (8...20).contains(lunarDay) { return .lantern }
        if (lunarMonth == 1 && lunarDay <= 15) || (lunarMonth == 12 && lunarDay >= 23) { return .spring }
        switch solarMonth {
        case 2...4: return .spring
        case 5...7: return .summer
        case 8...10: return .autumn
        default: return .winter
        }
    }
}

/// Full-bleed photo with the prototype `kenburns` drift. Never grows its parent's layout; the parent clips.
struct ArtBackdrop: View {
    let image: String
    var duration: Double = VNMotion.Loop.kenBurns

    var body: some View {
        Color.clear
            .overlay { Image(image).resizable().scaledToFill().vnKenBurns(duration: duration) }
            .clipped()
            .accessibilityHidden(true)
    }
}

/// Prototype `.sky-shade`: dark navy gradient that keeps white text readable on photos.
struct SkyShade: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: 0x0B1433, alpha: 0.62), location: 0),
                .init(color: Color(hex: 0x0B1433, alpha: 0.30), location: 0.38),
                .init(color: Color(hex: 0x0B1433, alpha: 0.55), location: 0.70),
                .init(color: Color(hex: 0x0B1433, alpha: 0.90), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Bronze-drum motif (`Assets.xcassets/Motif/Drum`, template) turning once per 90s.
struct DrumMotif: View {
    let size: CGFloat
    var opacity: Double = 0.3

    var body: some View {
        Image("Motif/Drum")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(Color.vnAccentImperialGold)
            .opacity(opacity)
            .vnSpinSlow(duration: VNMotion.Loop.drumTurn)
            .accessibilityHidden(true)
    }
}

/// Prototype `.art-panel`: rounded lunar-night card with a season photo, sky-shade, drum motif and centred content.
struct ArtPanel<Content: View>: View {
    let season: ArtSeason
    let height: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.vnNight
            ArtBackdrop(image: season.assetName)
            SkyShade()
            DrumMotif(size: 300)
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
