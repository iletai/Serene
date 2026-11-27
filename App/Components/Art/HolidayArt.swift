import SwiftUI
import VNCalendarDesignSystem
import VNCalendarDomain

/// Which artwork a holiday shows (design.html `holidayArt`). Holidays without a mapping keep the plain header.
enum HolidayArtKind {
    case tet
    case drum
    case flag(String)
    case flagFire

    init?(holiday: Holiday) {
        switch holiday.id {
        case "tet-nguyen-dan-1", "tet-nguyen-dan-2", "tet-nguyen-dan-3": self = .tet
        case "gio-to-hung-vuong": self = .drum
        case "quoc-khanh-vn": self = .flagFire
        case "giai-phong-mien-nam": self = .flag("Holiday/3004")
        case "quoc-te-lao-dong": self = .flag("Holiday/0105")
        default: return nil
        }
    }
}

/// Animated holiday artwork filling its container: Tet photo with falling petals, waving flag (with fireworks), or a drum.
struct HolidayArt: View {
    let kind: HolidayArtKind

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0B1433), Color(hex: 0x18276A)], startPoint: .topLeading, endPoint: .bottomTrailing)
            switch kind {
            case .tet:
                ArtBackdrop(image: "Holiday/tet", duration: VNMotion.Loop.kenBurnsHoliday)
                PetalFall()
            case .drum:
                DrumMotif(size: 240, opacity: 0.5)
            case .flag(let asset):
                Flag(asset: asset)
            case .flagFire:
                Flag(asset: "Holiday/dang")
                FireworksLayer().blendMode(.screen)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }

    private struct Flag: View {
        let asset: String

        var body: some View {
            ZStack {
                Color(hex: 0xDA251D)
                Color.clear
                    .overlay { Image(asset).resizable().scaledToFill() }
                    .clipped()
                    .vnFlagWave()
            }
        }
    }
}

/// Prototype `.petals`: ten gold and pink petals drifting down; hidden under Reduce Motion.
private struct PetalFall: View {
    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<10, id: \.self) { index in
                UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 0, bottomTrailingRadius: 6, topTrailingRadius: 0)
                    .fill(index % 3 == 2 ? Color(hex: 0xFF9FB2) : Color(hex: 0xFFD24D))
                    .frame(width: 10, height: 8)
                    .shadow(color: Color(hex: 0xFFD24D, alpha: 0.6), radius: 3)
                    .opacity(0.92)
                    .vnPetalFall(index: index)
                    .position(x: proxy.size.width * (CGFloat(index) * 0.1 + 0.03), y: -14)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Prototype `FIREWORKS_SVG`: five staggered bursts laid out in a 300x200 box that is scaled to fill (slice).
private struct FireworksLayer: View {
    private struct Spec {
        let x: CGFloat, y: CGFloat, radius: CGFloat, color: Color
    }

    private static let specs = [
        Spec(x: 70, y: 70, radius: 38, color: Color(hex: 0xF2C14E)),
        Spec(x: 210, y: 58, radius: 46, color: Color(hex: 0xFF8798)),
        Spec(x: 150, y: 120, radius: 32, color: .white),
        Spec(x: 250, y: 140, radius: 28, color: Color(hex: 0x7C9BFF)),
        Spec(x: 40, y: 150, radius: 24, color: Color(hex: 0xF7CF63))
    ]

    var body: some View {
        GeometryReader { proxy in
            let scale = max(proxy.size.width / 300, proxy.size.height / 200)
            let originX = (proxy.size.width - 300 * scale) / 2
            let originY = (proxy.size.height - 200 * scale) / 2
            ForEach(Self.specs.indices, id: \.self) { index in
                let spec = Self.specs[index]
                Burst(color: spec.color, scale: scale)
                    .frame(width: spec.radius * 2 * scale, height: spec.radius * 2 * scale)
                    .vnBurst(delay: Double(index) * VNMotion.Loop.burstStagger)
                    .position(x: originX + spec.x * scale, y: originY + spec.y * scale)
            }
        }
        .allowsHitTesting(false)
    }

    private struct Burst: View {
        let color: Color
        let scale: CGFloat

        var body: some View {
            ZStack {
                Rays().stroke(color, style: StrokeStyle(lineWidth: 2.2 * scale, lineCap: .round))
                Circle().fill(color).frame(width: 5 * scale, height: 5 * scale)
            }
        }
    }

    /// 14 rays from 25% to 100% of the radius.
    private struct Rays: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let radius = min(rect.width, rect.height) / 2
            for ray in 0..<14 {
                let angle = Double(ray) * .pi / 7
                let (sine, cosine) = (CGFloat(sin(angle)), CGFloat(cos(angle)))
                path.move(to: CGPoint(x: rect.midX + radius * 0.25 * cosine, y: rect.midY + radius * 0.25 * sine))
                path.addLine(to: CGPoint(x: rect.midX + radius * cosine, y: rect.midY + radius * sine))
            }
            return path
        }
    }
}
