import SwiftUI
import VNCalendarDesignSystem

/// A touch counts as a tap only if it ended close to where it began. A scroll or swipe that
/// starts on a cell travels further and must never activate it.
enum TapIntent {
    static let maxTravel: CGFloat = 10

    static func isTap(_ translation: CGSize) -> Bool {
        hypot(translation.width, translation.height) <= maxTravel
    }
}

private struct TapOnRelease: ViewModifier {
    let pressedScale: CGFloat
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed && !reduceMotion ? pressedScale : 1)
            .opacity(isPressed ? 0.88 : 1)
            .animation(reduceMotion ? VNAnimation.reduced : VNAnimation.press, value: isPressed)
            .contentShape(Rectangle())
            // Simultaneous so the enclosing ScrollView keeps its pan; the release check below rejects scrolls.
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { value, state, _ in state = TapIntent.isTap(value.translation) }
                    .onEnded { value in
                        if TapIntent.isTap(value.translation) { action() }
                    }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default, action)
    }
}

extension View {
    /// Fires `action` on touch-up only, and only when the finger did not travel (never after a scroll/swipe).
    func onTapRelease(pressedScale: CGFloat = 0.94, perform action: @escaping () -> Void) -> some View {
        modifier(TapOnRelease(pressedScale: pressedScale, action: action))
    }
}
