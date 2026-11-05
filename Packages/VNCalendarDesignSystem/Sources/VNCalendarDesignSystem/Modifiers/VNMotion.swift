import SwiftUI

/// Reduce Motion aware helpers. Every VN animation should go through these.
private struct VNAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? VNAnimation.reduced : animation, value: value)
    }
}

private struct VNAppearModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    let delay: Double
    let offset: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : offset)
            .onAppear {
                guard !shown else { return }
                let animation = reduceMotion ? VNAnimation.reduced : VNAnimation.appear.delay(delay)
                withAnimation(animation) { shown = true }
            }
    }
}

private struct VNTransitionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let transition: AnyTransition

    func body(content: Content) -> some View {
        content.transition(reduceMotion ? .opacity : transition)
    }
}

public extension View {
    /// `animation(_:value:)` that degrades to a short 0.15s fade-speed animation when Reduce Motion is on.
    func vnAnimation<V: Equatable>(_ animation: Animation = VNAnimation.selection, value: V) -> some View {
        modifier(VNAnimationModifier(animation: animation, value: value))
    }

    /// Staggered fade + slide-up entrance. Use `delay: Double(index) * 0.05` for stagger.
    /// Only for small, non-scrolling groups (headers, empty states, cards on first load).
    func vnAppear(delay: Double = 0, offset: CGFloat = 12) -> some View {
        modifier(VNAppearModifier(delay: delay, offset: offset))
    }

    /// Transition that becomes a plain opacity fade under Reduce Motion.
    func vnTransition(_ transition: AnyTransition) -> some View {
        modifier(VNTransitionModifier(transition: transition))
    }
}
