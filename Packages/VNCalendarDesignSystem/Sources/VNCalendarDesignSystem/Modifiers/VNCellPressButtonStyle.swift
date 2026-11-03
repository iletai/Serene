import SwiftUI

/// Press feedback for tappable cells, cards and rows. Respects Reduce Motion.
/// Use the default scale for grid cells; pass a subtler scale (e.g. 0.98) for full-width cards/rows.
public struct VNCellPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let pressedScale: CGFloat

    public init(pressedScale: CGFloat = 0.94) {
        self.pressedScale = pressedScale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? pressedScale : 1.0)
            .animation(reduceMotion ? .none : VNAnimation.cellSelection, value: configuration.isPressed)
    }
}
