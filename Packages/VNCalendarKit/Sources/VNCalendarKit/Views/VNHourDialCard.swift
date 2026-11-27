import SwiftUI
import VNCalendarDesignSystem
import VNCalendarDomain
import VNCalendarLunar

/// Ring dial of the twelve canh giờ with the auspicious ones lit, plus their list.
///
/// Mirrors the prototype's `.dial-card`: a 12-segment ring (labels at 79% radius)
/// with the auspicious count in the middle, and a two-column hour list on the right.
public struct VNHourDialCard: View {
    public let auspiciousHours: [EarthlyBranch]

    public init(auspiciousHours: [EarthlyBranch]) {
        self.auspiciousHours = auspiciousHours
    }

    public var body: some View {
        HStack(alignment: .center, spacing: VNSpacing.lg) {
            VNHourDialView(auspiciousHours: auspiciousHours)
                .frame(width: 132, height: 132)

            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                ForEach(auspiciousHours, id: \.self) { branch in
                    HStack(spacing: VNSpacing.sm) {
                        Circle()
                            .fill(Color.vnAccentSky)
                            .frame(width: 6, height: 6)
                            .accessibilityHidden(true)

                        Text(branch.vietnameseName)
                            .font(.vnDisplay(.footnote, weight: .semibold))
                            .foregroundColor(.vnTextPrimary)

                        Spacer(minLength: VNSpacing.xs)

                        Text(Self.hourRange(branch))
                            .font(.vnDisplay(.caption2))
                            .monospacedDigit()
                            .foregroundColor(.vnTextSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(VNSpacing.lg)
        .background(Color.vnBackgroundSecondary)
    }

    /// "23-01" → "23h – 01h"
    static func hourRange(_ branch: EarthlyBranch) -> String {
        let parts = branch.timeRange.split(separator: "-")
        guard parts.count == 2 else { return branch.timeRange }
        return "\(parts[0])h – \(parts[1])h"
    }
}

/// The ring itself: twelve 28° segments, auspicious ones filled Hội An blue.
public struct VNHourDialView: View {
    public let auspiciousHours: [EarthlyBranch]

    public init(auspiciousHours: [EarthlyBranch]) {
        self.auspiciousHours = auspiciousHours
    }

    private var goodBranches: Set<EarthlyBranch> { Set(auspiciousHours) }

    public var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = min(size.width, size.height) / 2 - 1
            let inner = outer * 0.645
            for branch in EarthlyBranch.allCases {
                drawSegment(branch, in: &context, center: center, outer: outer, inner: inner)
            }
            drawCenter(in: &context, center: center, radius: outer)
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private func drawSegment(
        _ branch: EarthlyBranch,
        in context: inout GraphicsContext,
        center: CGPoint,
        outer: CGFloat,
        inner: CGFloat
    ) {
        let mid = Double(branch.rawValue) * 30
        let start = Angle(degrees: mid - 14 - 90)
        let end = Angle(degrees: mid + 14 - 90)
        let isGood = goodBranches.contains(branch)

        var path = Path()
        path.move(to: point(center: center, radius: outer, angle: start))
        path.addArc(center: center, radius: outer, startAngle: start, endAngle: end, clockwise: false)
        path.addLine(to: point(center: center, radius: inner, angle: end))
        path.addArc(center: center, radius: inner, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()

        context.fill(path, with: .color(isGood ? .vnAccentSky : .vnBackgroundTertiary))

        let label = context.resolve(
            Text(branch.vietnameseName)
                .font(.vnDisplay(size: 10, weight: .semibold))
                .foregroundColor(isGood ? .vnOnAccent : .vnTextSecondary)
        )
        context.draw(label, at: point(center: center, radius: outer * 0.82, angle: .degrees(mid - 90)))
    }

    private func drawCenter(in context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let count = context.resolve(
            Text("\(auspiciousHours.count)")
                .font(.vnDisplay(size: 26, weight: .heavy))
                .foregroundColor(.vnTextPrimary)
        )
        context.draw(count, at: CGPoint(x: center.x, y: center.y - radius * 0.09))

        let caption = context.resolve(
            Text("today.dial_caption")
                .font(.vnDisplay(size: 10, weight: .medium))
                .foregroundColor(.vnTextSecondary)
        )
        context.draw(caption, at: CGPoint(x: center.x, y: center.y + radius * 0.18))
    }

    private func point(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(cos(angle.radians)),
            y: center.y + radius * CGFloat(sin(angle.radians))
        )
    }

    private var accessibilityText: String {
        let names = auspiciousHours.map { "\($0.vietnameseName) \(VNHourDialCard.hourRange($0))" }
        return String(format: String(localized: "today.dial_accessibility"), auspiciousHours.count, names.joined(separator: ", "))
    }
}
