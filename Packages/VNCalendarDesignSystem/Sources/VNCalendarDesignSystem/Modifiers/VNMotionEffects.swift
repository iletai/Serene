import SwiftUI

// MARK: - Rise (staggered entrance)

public extension View {
    /// Prototype `rise` / `bloc-in`: fade in while sliding up 18pt.
    /// Pass the item index for the carousel's 60ms stagger.
    func vnRise(index: Int = 0, baseDelay: Double = 0, stagger: Double = 0.06, distance: CGFloat = 18) -> some View {
        vnAppear(delay: baseDelay + Double(index) * stagger, offset: distance)
    }
}

// MARK: - Idle loops

private struct VNBobModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lifted = false
    let distance: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(y: lifted ? -distance : 0)
            .onAppear {
                guard !reduceMotion, !lifted else { return }
                withAnimation(.easeInOut(duration: VNMotion.Loop.bob / 2).repeatForever(autoreverses: true)) {
                    lifted = true
                }
            }
            .onChange(of: reduceMotion) { _, reduced in
                guard reduced else { return }
                withAnimation(nil) { lifted = false }
            }
    }
}

private struct VNSwayModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var leaned = false
    let from: Double
    let to: Double
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(leaned ? to : from), anchor: anchor)
            .onAppear {
                guard !reduceMotion, !leaned else { return }
                withAnimation(.easeInOut(duration: VNMotion.Loop.sway / 2).repeatForever(autoreverses: true)) {
                    leaned = true
                }
            }
            .onChange(of: reduceMotion) { _, reduced in
                guard reduced else { return }
                withAnimation(nil) { leaned = false }
            }
    }
}

private struct VNSpinSlowModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var angle: Double = 0
    let duration: Double

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .onAppear {
                guard !reduceMotion, angle == 0 else { return }
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
            .onChange(of: reduceMotion) { _, reduced in
                guard reduced else { return }
                withAnimation(nil) { angle = 0 }
            }
    }
}

private struct VNGlowPulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(expanded ? 1.15 : 0.9)
            .opacity(expanded ? 0.8 : 0.35)
            .onAppear {
                guard !reduceMotion, !expanded else { return }
                withAnimation(.easeInOut(duration: VNMotion.Loop.glow / 2).repeatForever(autoreverses: true)) {
                    expanded = true
                }
            }
            .onChange(of: reduceMotion) { _, reduced in
                guard reduced else { return }
                withAnimation(nil) { expanded = false }
            }
    }
}

private struct VNMoonGlowModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.vnAccentImperialGold.opacity(glowing ? 0.85 : 0.35),
                radius: glowing ? 14 : 5
            )
            .onAppear {
                guard !reduceMotion, !glowing else { return }
                withAnimation(.easeInOut(duration: VNMotion.Loop.moonGlow / 2).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
            .onChange(of: reduceMotion) { _, reduced in
                guard reduced else { return }
                withAnimation(nil) { glowing = false }
            }
    }
}

private struct VNCrownShineModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shining = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.vnAccentImperialGold.opacity(shining ? 0.8 : 0.3),
                radius: shining ? 32 : 22,
                y: 8
            )
            .onAppear {
                guard !reduceMotion, !shining else { return }
                withAnimation(.easeInOut(duration: VNMotion.Loop.crownShine / 2).repeatForever(autoreverses: true)) {
                    shining = true
                }
            }
            .onChange(of: reduceMotion) { _, reduced in
                guard reduced else { return }
                withAnimation(nil) { shining = false }
            }
    }
}

private enum VNTwinklePhase: CaseIterable {
    case rest, big, small
}

private struct VNTwinkleModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.phaseAnimator(VNTwinklePhase.allCases) { view, phase in
                switch phase {
                case .rest: view
                case .big: view.scaleEffect(1.2).rotationEffect(.degrees(20))
                case .small: view.scaleEffect(0.94).rotationEffect(.degrees(-6))
                }
            } animation: { phase in
                phase == .rest ? .easeInOut(duration: 1.8) : .easeInOut(duration: 0.4)
            }
        }
    }
}

private enum VNSwingPhase: CaseIterable {
    case rest, back, forward, settle
}

private struct VNSwingModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.phaseAnimator(VNSwingPhase.allCases) { view, phase in
                switch phase {
                case .rest: view
                case .back: view.rotationEffect(.degrees(-22))
                case .forward: view.rotationEffect(.degrees(16))
                case .settle: view.rotationEffect(.degrees(-6))
                }
            } animation: { phase in
                phase == .rest ? .easeInOut(duration: 1.6) : .easeInOut(duration: 0.35)
            }
        }
    }
}

// MARK: - One-shot keyframes

private struct VNIconPopValues {
    var scale: CGFloat = 0.4
    var rotation: Double = -18
    var opacity: Double = 0
}

private struct VNIconPopModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var started = false
    let delay: Double

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .keyframeAnimator(initialValue: VNIconPopValues(), trigger: started) { view, value in
                    view
                        .scaleEffect(value.scale)
                        .rotationEffect(.degrees(value.rotation))
                        .opacity(value.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        CubicKeyframe(1.12, duration: 0.38)
                        CubicKeyframe(1, duration: 0.26)
                    }
                    KeyframeTrack(\.rotation) {
                        CubicKeyframe(4, duration: 0.38)
                        CubicKeyframe(0, duration: 0.26)
                    }
                    KeyframeTrack(\.opacity) {
                        CubicKeyframe(1, duration: 0.38)
                        CubicKeyframe(1, duration: 0.26)
                    }
                }
                .task {
                    guard !started else { return }
                    if delay > 0 {
                        try? await Task.sleep(for: .seconds(delay))
                    }
                    started = true
                }
        }
    }
}

private struct VNScalePulseValues {
    var scale: CGFloat = 1
}

private struct VNSelectionPulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fired = false
    let active: Bool

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: VNScalePulseValues(), trigger: fired) { view, value in
                view.scaleEffect(value.scale)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(0.94, duration: 0.08)
                    CubicKeyframe(1.06, duration: 0.12)
                    CubicKeyframe(1, duration: 0.12)
                }
            }
            .onChange(of: active) { _, isActive in
                guard isActive, !reduceMotion else { return }
                fired.toggle()
            }
    }
}

private struct VNBeatModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fired = false
    let active: Bool

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: VNScalePulseValues(), trigger: fired) { view, value in
                view.scaleEffect(value.scale)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(1.22, duration: 0.16)
                    CubicKeyframe(1, duration: 0.14)
                    CubicKeyframe(1.12, duration: 0.14)
                    CubicKeyframe(1, duration: 0.18)
                }
            }
            .onChange(of: active) { _, isActive in
                guard isActive, !reduceMotion else { return }
                fired.toggle()
            }
    }
}

private struct VNTabBounceValues {
    var scale: CGFloat = 1
    var offsetY: CGFloat = 0
}

private struct VNTabBounceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fired = false
    let active: Bool

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: VNTabBounceValues(), trigger: fired) { view, value in
                view.scaleEffect(value.scale).offset(y: value.offsetY)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(0.78, duration: 0.10)
                    CubicKeyframe(1.16, duration: 0.20)
                    CubicKeyframe(1, duration: 0.22)
                }
                KeyframeTrack(\.offsetY) {
                    CubicKeyframe(0, duration: 0.10)
                    CubicKeyframe(-2, duration: 0.20)
                    CubicKeyframe(0, duration: 0.22)
                }
            }
            .onChange(of: active) { _, isActive in
                guard isActive, !reduceMotion else { return }
                fired.toggle()
            }
    }
}

private struct VNSpinOnceValues {
    var rotation: Double = 0
}

private struct VNSpinOnceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fired = false
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: VNSpinOnceValues(), trigger: fired) { view, value in
                view.rotationEffect(.degrees(value.rotation))
            } keyframes: { _ in
                KeyframeTrack(\.rotation) {
                    CubicKeyframe(180, duration: 0.7)
                }
            }
            .onChange(of: trigger) { _, _ in
                guard !reduceMotion else { return }
                fired.toggle()
            }
    }
}

private struct VNNudgeValues {
    var offsetY: CGFloat = 0
}

private struct VNNudgeModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fired = false
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: VNNudgeValues(), trigger: fired) { view, value in
                view.offset(y: value.offsetY)
            } keyframes: { _ in
                KeyframeTrack(\.offsetY) {
                    CubicKeyframe(0, duration: 0.25)
                    CubicKeyframe(-3, duration: 0.08)
                    CubicKeyframe(0, duration: 0.27)
                }
            }
            .onChange(of: trigger) { _, _ in
                guard !reduceMotion else { return }
                fired.toggle()
            }
    }
}

private struct VNRingValues {
    var rotation: Double = 0
}

private struct VNRingModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fired = false
    let active: Bool

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: VNRingValues(), trigger: fired) { view, value in
                view.rotationEffect(.degrees(value.rotation), anchor: .top)
            } keyframes: { _ in
                KeyframeTrack(\.rotation) {
                    CubicKeyframe(16, duration: 0.11)
                    CubicKeyframe(-14, duration: 0.11)
                    CubicKeyframe(10, duration: 0.11)
                    CubicKeyframe(-6, duration: 0.11)
                    CubicKeyframe(2, duration: 0.11)
                    CubicKeyframe(0, duration: 0.16)
                }
            }
            .onChange(of: active) { _, isActive in
                guard isActive, !reduceMotion else { return }
                fired.toggle()
            }
    }
}

// MARK: - Public API

public extension View {
    /// `bob`: a 2pt vertical float, 3.6s cycle.
    func vnBob(distance: CGFloat = 2) -> some View {
        modifier(VNBobModifier(distance: distance))
    }

    /// `sway`: -6° → 8° rotation, 3.8s cycle.
    func vnSway(from: Double = -6, to: Double = 8, anchor: UnitPoint = .center) -> some View {
        modifier(VNSwayModifier(from: from, to: to, anchor: anchor))
    }

    /// `spin-slow`: one full turn per `duration` seconds.
    func vnSpinSlow(duration: Double = VNMotion.Loop.spinSlow) -> some View {
        modifier(VNSpinSlowModifier(duration: duration))
    }

    /// `glow`: opacity .35 → .8 and scale .9 → 1.15, 3.6s cycle.
    func vnGlowPulse() -> some View {
        modifier(VNGlowPulseModifier())
    }

    /// `moon-glow`: gold drop-shadow pulsing 5pt → 14pt, 4.2s cycle.
    func vnMoonGlow() -> some View {
        modifier(VNMoonGlowModifier())
    }

    /// `crown-shine`: gold shadow pulsing 22pt → 32pt, 3.2s cycle.
    func vnCrownShine() -> some View {
        modifier(VNCrownShineModifier())
    }

    /// `twinkle`: occasional scale/rotate flick, 4s cycle.
    func vnTwinkle() -> some View {
        modifier(VNTwinkleModifier())
    }

    /// `swing`: occasional compass swing, 4.4s cycle.
    func vnSwing() -> some View {
        modifier(VNSwingModifier())
    }

    /// `ico-pop`: 0.4 scale, -18° rotation → overshoot → settle, 640ms. Stagger with `delay`.
    func vnIconPop(delay: Double = 0) -> some View {
        modifier(VNIconPopModifier(delay: delay))
    }

    /// Cell selection pulse: .94 → 1.06 → 1, fires only when `active` turns true.
    func vnSelectionPulse(active: Bool) -> some View {
        modifier(VNSelectionPulseModifier(active: active))
    }

    /// `beat`: heart double-thump, fires only when `active` turns true.
    func vnBeat(active: Bool) -> some View {
        modifier(VNBeatModifier(active: active))
    }

    /// `tab-bounce`: .78 → 1.16 → 1 with a 2pt hop, fires when `active` turns true.
    func vnTabBounce(active: Bool) -> some View {
        modifier(VNTabBounceModifier(active: active))
    }

    /// `spin-once`: 180° turn, fires every time `trigger` changes.
    func vnSpinOnce(trigger: Bool) -> some View {
        modifier(VNSpinOnceModifier(trigger: trigger))
    }

    /// `nudge`: 3pt hop, fires every time `trigger` changes.
    func vnNudge(trigger: Bool) -> some View {
        modifier(VNNudgeModifier(trigger: trigger))
    }

    /// `ring`: bell-style shake, fires only when `active` turns true.
    func vnRing(active: Bool) -> some View {
        modifier(VNRingModifier(active: active))
    }
}
