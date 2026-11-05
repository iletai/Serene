import SwiftUI

/// Classifies a drag as a horizontal navigation swipe, ignoring vertical scrolls with horizontal drift.
public enum SwipeIntent: Equatable, Sendable {
    case previous, next, none

    static let distanceThreshold: CGFloat = 60
    static let predictedThreshold: CGFloat = 120
    static let axisRatio: CGFloat = 1.5

    /// True when the drag is dominantly horizontal (width > 1.5 x height).
    public static func isHorizontal(_ translation: CGSize) -> Bool {
        abs(translation.width) > abs(translation.height) * axisRatio
    }

    /// Resolves a finished drag. `predictedEnd` defaults to `translation` (no momentum).
    public static func classify(translation: CGSize, predictedEnd: CGSize? = nil) -> SwipeIntent {
        guard isHorizontal(translation) else { return .none }
        let predicted = predictedEnd?.width ?? translation.width
        if translation.width < -distanceThreshold || predicted < -predictedThreshold { return .next }
        if translation.width > distanceThreshold || predicted > predictedThreshold { return .previous }
        return .none
    }
}

private struct AxisLockedSwipe: ViewModifier {
    @Binding var offset: CGFloat
    let onPrevious: () -> Void
    let onNext: () -> Void

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        // Follow the finger only for horizontal drags; a vertical scroll must not jitter the card.
                        let target = SwipeIntent.isHorizontal(value.translation) ? value.translation.width * 0.4 : 0
                        if offset != target { offset = target }
                    }
                    .onEnded { value in
                        let intent = SwipeIntent.classify(
                            translation: value.translation,
                            predictedEnd: value.predictedEndTranslation
                        )
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            switch intent {
                            case .next: onNext()
                            case .previous: onPrevious()
                            case .none: break
                            }
                            offset = 0
                        }
                    }
            )
    }
}

extension View {
    /// Horizontal swipe navigation that coexists with an enclosing vertical ScrollView.
    func axisLockedSwipe(offset: Binding<CGFloat>, onPrevious: @escaping () -> Void, onNext: @escaping () -> Void) -> some View {
        modifier(AxisLockedSwipe(offset: offset, onPrevious: onPrevious, onNext: onNext))
    }
}
