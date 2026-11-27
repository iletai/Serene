import SwiftUI

// MARK: - Family screen loops (prototype `smoke`, `next-glow`)

private struct VNSmokeValues {
    var opacity: Double = 0
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 2
}

private struct VNSmokeModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.keyframeAnimator(initialValue: VNSmokeValues(), repeating: true) { view, value in
                view.opacity(value.opacity).offset(x: value.offsetX, y: value.offsetY)
            } keyframes: { _ in
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.9, duration: 0.84)
                    LinearKeyframe(0, duration: 1.96)
                }
                KeyframeTrack(\.offsetX) { LinearKeyframe(3, duration: VNMotion.Loop.smoke) }
                KeyframeTrack(\.offsetY) { LinearKeyframe(-8, duration: VNMotion.Loop.smoke) }
            }
        }
    }
}

private struct VNNextGlowModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowing = false
    let isActive: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.vnAccentImperialGold.opacity(glowing ? 0.45 : 0), lineWidth: glowing ? 4 : 0)
                    .allowsHitTesting(false)
            }
            .onAppear { update() }
            .onChange(of: isActive) { _, _ in update() }
            .onChange(of: reduceMotion) { _, _ in update() }
    }

    private func update() {
        if isActive, !reduceMotion {
            guard !glowing else { return }
            withAnimation(.easeInOut(duration: VNMotion.Loop.nextGlow / 2).repeatForever(autoreverses: true)) {
                glowing = true
            }
        } else {
            withAnimation(nil) { glowing = false }
        }
    }
}

public extension View {
    /// Prototype `smoke`: incense smoke wisp rising and fading, looping. Static under Reduce Motion.
    func vnSmoke() -> some View {
        modifier(VNSmokeModifier())
    }

    /// Prototype `next-glow`: a gold ring that pulses around the next upcoming item. Off under Reduce Motion.
    func vnNextGlow(isActive: Bool, cornerRadius: CGFloat) -> some View {
        modifier(VNNextGlowModifier(isActive: isActive, cornerRadius: cornerRadius))
    }
}
