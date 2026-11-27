import SwiftUI

// MARK: - Artwork loops (prototype `kenburns`, `flag-wave`, `burst`, `petal-fall`)
// Every loop is static (or hidden, for petals) under Reduce Motion and stops when it turns on.

private struct VNKenBurnsModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var zoomed = false
    let duration: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(zoomed ? 1.14 : 1.02, anchor: UnitPoint(x: 0.6, y: 0.4))
            .onAppear { update() }
            .onChange(of: reduceMotion) { _, _ in update() }
    }

    private func update() {
        if reduceMotion {
            withAnimation(nil) { zoomed = false }
        } else if !zoomed {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) { zoomed = true }
        }
    }
}

private struct VNFlagWaveModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var waving = false

    /// skewY(-1.6deg) scaleX(1.03). The skew offset depends only on x, so the leading edge stays fixed.
    private static let wave = CGAffineTransform(a: 1.03, b: tan(-1.6 * .pi / 180), c: 0, d: 1, tx: 0, ty: 0)

    func body(content: Content) -> some View {
        content
            .transformEffect(waving ? Self.wave : .identity)
            .onAppear { update() }
            .onChange(of: reduceMotion) { _, _ in update() }
    }

    private func update() {
        if reduceMotion {
            withAnimation(nil) { waving = false }
        } else if !waving {
            withAnimation(.easeInOut(duration: VNMotion.Loop.flagWave / 2).repeatForever(autoreverses: true)) { waving = true }
        }
    }
}

private struct VNBurstValues {
    var scale: CGFloat = 0.1
    var opacity: Double = 0
}

private struct VNBurstModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var started = false
    let delay: Double

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content.opacity(0.8)
        } else if started {
            content.keyframeAnimator(initialValue: VNBurstValues(), repeating: true) { view, value in
                view.scaleEffect(value.scale).opacity(value.opacity)
            } keyframes: { _ in
                let cycle = VNMotion.Loop.burst
                KeyframeTrack(\.scale) {
                    CubicKeyframe(1, duration: cycle * 0.6, endVelocity: 0)
                    CubicKeyframe(1.15, duration: cycle * 0.4)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: cycle * 0.12)
                    LinearKeyframe(0.9, duration: cycle * 0.48)
                    LinearKeyframe(0, duration: cycle * 0.4)
                }
            }
        } else {
            content.opacity(0)
                .task {
                    try? await Task.sleep(for: .seconds(delay))
                    started = true
                }
        }
    }
}

private struct VNPetalFallModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let index: Int
    let distance: CGFloat

    func body(content: Content) -> some View {
        if reduceMotion {
            content.hidden()
        } else {
            let duration = 5 + Double(index) * 0.4
            TimelineView(.animation) { context in
                // `animation-delay: k * -.7s` starts each petal part-way through its fall.
                let elapsed = context.date.timeIntervalSinceReferenceDate + Double(index) * 0.7
                let progress = elapsed.truncatingRemainder(dividingBy: duration) / duration
                content
                    .rotationEffect(.degrees(360 * progress))
                    .offset(x: 34 * progress, y: distance * progress)
            }
        }
    }
}

public extension View {
    /// `kenburns`: slow 1.02 → 1.14 zoom (anchor 60% 40%), alternating. Put it on the image, clip in the container.
    func vnKenBurns(duration: Double = VNMotion.Loop.kenBurns) -> some View {
        modifier(VNKenBurnsModifier(duration: duration))
    }

    /// `flag-wave`: skewY -1.6° and scaleX 1.03 from the leading edge, 4.5s cycle.
    func vnFlagWave() -> some View {
        modifier(VNFlagWaveModifier())
    }

    /// `burst`: one firework growing from .1 to 1.15 while fading in and out, 3.2s cycle, starting after `delay`.
    /// Static at .8 opacity under Reduce Motion. Blend the whole layer with `.blendMode(.screen)` over a flag.
    func vnBurst(delay: Double = 0) -> some View {
        modifier(VNBurstModifier(delay: delay))
    }

    /// `petal-fall`: drifts 34pt right and `distance` down while turning 360°; period 5s + index * .4s. Hidden under Reduce Motion.
    func vnPetalFall(index: Int, distance: CGFloat = 240) -> some View {
        modifier(VNPetalFallModifier(index: index, distance: distance))
    }
}
