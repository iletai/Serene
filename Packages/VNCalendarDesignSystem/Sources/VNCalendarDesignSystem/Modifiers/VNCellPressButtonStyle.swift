import SwiftUI

public struct VNCellPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1.0)
            .animation(reduceMotion ? .none : VNAnimation.cellSelection, value: configuration.isPressed)
    }
}
